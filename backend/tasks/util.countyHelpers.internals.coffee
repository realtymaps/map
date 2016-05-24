_ = require 'lodash'
Promise = require 'bluebird'
dbs = require '../config/dbs'
logger = require('../config/logger').spawn('task:util:countyHelpers:internals')
tables = require '../config/tables'
dataLoadHelpers = require './util.dataLoadHelpers'

_documentFinalize = (fnName, cbPromise) ->
  logger.debug () -> "#{fnName} STARTED"

  cbPromise()
  .then (entries) ->
    logger.debug () -> "#{fnName} FINISHED"
    entries

finalizeDataTax = ({subtask, id, data_source_id}) ->
  _documentFinalize "finalizeDataTax", () ->
    tables.property.tax(subid: subtask.data.normalSubid)
    .select('*')
    .where
      rm_property_id: id
      data_source_id: data_source_id || subtask.task_name
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .orderByRaw('close_date DESC NULLS LAST')
    .then (taxEntries=[]) ->
      if taxEntries.length == 0
        # not sure if this should ever be possible, but we'll handle it anyway
        return tables.deletes.property()
        .insert
          rm_property_id: id
          data_source_id: data_source_id || subtask.task_name
          batch_id: subtask.batch_id
      if subtask.data.cause != 'tax' && taxEntries[0]?.batch_id == subtask.batch_id
        logger.debug "batch_id mismatch!!"
        logger.debug "subtask.data.cause: #{subtask.data.cause}"
        logger.debug "subtask.data.batch_id: #{subtask.data.batch_id} vs #{taxEntries[0]?.batch_id}"
        # since the same rm_property_id might get enqueued for finalization multiple times, we GTFO based on the priority
        # of the given enqueue source , in the following order: tax, deed, mortgage.  So if this instance wasn't enqueued
        # because of tax data, but the tax data appears to have been updated in this same batch, we bail and let tax take
        # care of it.
        return

      taxEntries


finalizeDataDeed = ({subtask, id, data_source_id}) ->
  _documentFinalize "finalizeDataDeed", () ->
    tables.property.deed(subid: subtask.data.normalSubid)
    .select('*')
    .where
      rm_property_id: id
      data_source_id: data_source_id || subtask.task_name
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .orderByRaw('close_date ASC NULLS FIRST')
    .then (deedEntries=[]) ->
      if subtask.data.cause == 'mortgage' && deedEntries[0]?.batch_id == subtask.batch_id
        # see above comment about GTFO shortcut logic.  This part lets mortgage give priority to deed.
        return
      deedEntries



finalizeDataMortgage = ({subtask, id, data_source_id}) ->
  _documentFinalize "finalizeDataMortgage", () ->
    tables.property.mortgage(subid: subtask.data.normalSubid)
    .select('*')
    .where
      rm_property_id: id
      data_source_id: data_source_id || subtask.task_name
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .orderByRaw('close_date ASC NULLS FIRST')


_promoteValues = ({taxEntries, deedEntries, mortgageEntries, parcel}) ->
  tax = dataLoadHelpers.finalizeEntry(taxEntries)
  tax.data_source_type = 'county'
  _.extend(tax, parcel[0])

  # TODO: consider going through salesHistory to make it essentially a diff, with changed values only for certain
  # TODO: static data fields?

  # now that we have an ordered sales history, overwrite that into the tax record
  saleFields = ['price', 'close_date', 'parcel_id', 'owner_name', 'owner_name_2', 'address', 'owner_address', 'property_type', 'zoning']
  tax.subscriber_groups.mortgage = mortgageEntries
  lastSale = deedEntries.pop()
  if lastSale?
    tax.subscriber_groups.owner = lastSale.subscriber_groups.owner
    tax.subscriber_groups.deed = lastSale.subscriber_groups.deed
    for field in saleFields
      tax[field] = lastSale[field]
    # save the MLS promoted values for easier access
    promotedValues =
      owner_name: lastSale.owner_name
      owner_name_2: lastSale.owner_name_2
      zoning: lastSale.zoning
  else
    # save the MLS promoted values for easier access
    promotedValues =
      owner_name: tax.owner_name
      owner_name_2: tax.owner_name_2
      zoning: tax.zoning
  tax.shared_groups.sale = []
  tax.subscriber_groups.deedHistory = []

  for deedInfo in deedEntries
    tax.shared_groups.sale.push(price: deedInfo.price, close_date: deedInfo.close_date)
    tax.subscriber_groups.deedHistory.push(deedInfo.subscriber_groups.owner.concat(deedInfo.subscriber_groups.deed))

  {promotedValues,tax}

_updateDataCombined = ({subtask, id, data_source_id, transaction, tax}) ->
  tables.property.combined(transaction: transaction)
  .where
    rm_property_id: id
    data_source_id: data_source_id || subtask.task_name
    active: false
  .delete()
  .then () ->
    tables.property.combined(transaction: transaction)
    .insert(tax)

finalizeJoin = ({subtask, id, data_source_id, delay, transaction}) ->
  delay ?= 100

  (taxEntries, deedEntries, mortgageEntries=[], parcel=[]) ->
    _documentFinalize "finalizeJoin", () ->
      # TODO: does this need to be discriminated further?  speculators can resell a property the same day they buy it with
      # TODO: simultaneous closings, how do we properly sort to account for that?
      {promotedValues,tax} = _promoteValues({taxEntries, deedEntries, mortgageEntries, parcel})

      Promise.delay(delay)  #throttle for heroku's sake
      .then () ->
        if !_.isEqual(promotedValues, tax.promoted_values)
          # need to save back promoted values to the normal table
          tables.property.tax(subid: subtask.data.normalSubid)
          .where
            data_source_id: data_source_id || subtask.task_name
            data_source_uuid: tax.data_source_uuid
          .update(promoted_values: promotedValues)
        else
          Promise.resolve()
      .then () ->
        delete tax.promoted_values

        #this may have been a deadlock from parcels
        #we must use an existing transaction if there is one
        if transaction?
          return _updateDataCombined {subtask, id, data_source_id, transaction, tax}

        dbs.get('main').transaction (trx) ->
          _updateDataCombined {subtask, id, data_source_id, transaction: trx, tax}



module.exports = {
  finalizeDataTax
  finalizeDataDeed
  finalizeDataMortgage
  finalizeJoin
}
