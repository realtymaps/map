_ = require 'lodash'
Promise = require 'bluebird'
dbs = require '../config/dbs'
logger = require('../config/logger').spawn('task:countyHelpers:internals')
tables = require '../config/tables'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
moment = require 'moment'
sqlHelpers = require '../utils/util.sql.helpers'


finalizeDataTax = ({subtask, id, data_source_id, forceFinalize}) ->
  q = tables.normalized.tax(subid: [data_source_id, subtask.data.fips_code])

  sqlHelpers.checkTableExists(q)
  .then (exists) ->
    if !exists
      return null

    q.select('*')
    .where(rm_property_id: id)
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .orderByRaw('recording_date DESC NULLS LAST')
    q
    .then (taxEntries=[]) ->
      if taxEntries.length == 0
        return null  # sometimes this might cover up a real error, but there are semi-legitimate cases where this can happen
      if !forceFinalize && subtask.data.cause != 'tax' && taxEntries[0].batch_id == subtask.batch_id
        logger.debug "GTFO to allow finalize from tax instead of: #{subtask.data.cause}"
        # since the same rm_property_id might get enqueued for finalization multiple times, we GTFO based on the priority
        # of the given enqueue source, in the following order: tax, deed, mortgage.  So if this instance wasn't enqueued
        # because of tax data, but the tax data appears to have been updated in this same batch, we bail and let tax take
        # care of it.
        return null
      return taxEntries


finalizeDataDeed = ({subtask, id, data_source_id, forceFinalize}) ->
  q = tables.normalized.deed(subid: [data_source_id, subtask.data.fips_code])

  sqlHelpers.checkTableExists(q)
  .then (exists) ->
    if !exists
      return null

    q.select('*')
    .where(rm_property_id: id)
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .orderByRaw('close_date DESC NULLS LAST')
    q
    .then (deedEntries=[]) ->
      if !forceFinalize && subtask.data.cause == 'mortgage' && deedEntries[0]?.batch_id == subtask.batch_id
        logger.debug "GTFO to allow finalize from deed instead of: #{subtask.data.cause}"
        # see above comment about GTFO shortcut logic.  This part lets mortgage give priority to deed.
        return null
      return deedEntries


finalizeDataMortgage = ({subtask, id, data_source_id}) ->

  q = tables.normalized.mortgage(subid: [data_source_id, subtask.data.fips_code])

  sqlHelpers.checkTableExists(q)
  .then (exists) ->
    if !exists
      return null

    q.select('*')
    .where(rm_property_id: id)
    .whereNull('deleted')
    .orderBy('rm_property_id')
    .orderBy('deleted')
    .orderByRaw('close_date DESC NULLS LAST')
    q.then (mortgageEntries) ->
      return mortgageEntries


_finalizeEntry = ({entries, subtask, data_source_id}) -> Promise.try ->
  mainEntry = _.clone(entries[0])
  delete entries[0].shared_groups
  delete entries[0].subscriber_groups
  delete entries[0].hidden_fields
  delete entries[0].ungrouped_fields

  delete mainEntry.deleted
  delete mainEntry.rm_inserted_time
  delete mainEntry.rm_modified_time
  mainEntry.prior_entries = sqlHelpers.safeJsonArray(entries)
  mainEntry.address = sqlHelpers.safeJsonArray(mainEntry.address)
  mainEntry.owner_address = sqlHelpers.safeJsonArray(mainEntry.owner_address)
  mainEntry.change_history = sqlHelpers.safeJsonArray(mainEntry.change_history)
  mainEntry.update_source = subtask.task_name
  mainEntry.data_source_id = data_source_id
  mainEntry.baths_total = mainEntry.baths?.filter
  mainEntry


_promoteValues = ({taxEntries, deedEntries, mortgageEntries, parcelEntries, subtask, data_source_id}) ->
  _finalizeEntry({entries: taxEntries, subtask, data_source_id})
  .then (tax) ->
    tax.data_source_type = 'county'
    if parcelEntries[0]
      tax.geometry = parcelEntries[0].geometry
      tax.geometry_raw = parcelEntries[0].geometry_raw
      tax.geometry_center = parcelEntries[0].geometry_center
      tax.geometry_center_raw = parcelEntries[0].geometry_center_raw

    # all county data gets 'sold' status -- it will be differentiated by the frontend's sold timeframe filter
    tax.status = 'sold'
    tax.status_display = 'sold'

    saleFields = ['price', 'close_date', 'recording_date', 'parcel_id', 'owner_name', 'owner_name_2', 'address', 'owner_address', 'property_type']

    # we need to check to see if we have a deed record that represents a sale more recent than what our tax records show,
    # and if so, overwrite the owner, deed, and sale info with that from the deed record (since it would have the tax
    # info by default)
    lastSaleIndex = null
    # look for the last deed entry that is actually the same property (i.e. same legal unit number) -- when a property
    # gets split, it appears the initial sales all get marked on the original parcel number (or at least that's how it is
    # in some counties).  We don't want to lose those sale records, but we also don't want to override the tax info for
    # the main parcel with info from the sale of a split-off
    for deedEntry,i in deedEntries
      deedEntry.sale_date = deedEntry.close_date || deedEntry.recording_date
      delete deedEntry.close_date
      delete deedEntry.recording_date
      if !lastSaleIndex? && (tax.legal_unit_number == deedEntry.legal_unit_number || (!tax.legal_unit_number && !deedEntry.legal_unit_number))
        lastSaleIndex = i
    if lastSaleIndex?
      [lastSale] = deedEntries.splice(lastSaleIndex, 1)
      try
        deedRecordingDate = moment(lastSale.sale_date).startOf('day')
        taxRecordingDate = moment(tax.recording_date).startOf('day')
        if deedRecordingDate.isAfter(taxRecordingDate)
          tax.subscriber_groups.owner = lastSale.subscriber_groups.owner
          tax.subscriber_groups.deed = lastSale.subscriber_groups.deed
          for field in saleFields
            tax[field] = lastSale[field]
        else if deedRecordingDate.isSame(taxRecordingDate)
          for field in saleFields
            tax[field] ?= lastSale[field]
      catch err
        logger.warn(msg = "Error while processing tax and deed data: #{err}")
        logger.warn("deedEntries.length: #{deedEntries.length}")
        logger.warn("lastSaleIndex:  #{lastSaleIndex}")
        logger.warn("lastSale:  #{JSON.stringify(lastSale)}")
        logger.warn("tax:  #{JSON.stringify(tax)}")
        throw new SoftFail(msg)

    tax.close_date = tax.close_date || tax.recording_date
    delete tax.recording_date
    delete tax.legal_unit_number

    tax.subscriber_groups.mortgageHistory = mortgageEntries
    tax.subscriber_groups.deedHistory = deedEntries

    tax

_updateDataCombined = ({subtask, id, data_source_id, transaction, tax}) ->
  tables.finalized.combined({transaction})
  .where
    rm_property_id: id
    data_source_id: data_source_id
  .delete()
  .then () ->
    tables.finalized.combined({transaction})
    .insert(tax)

finalizeJoin = ({subtask, id, data_source_id, transaction, taxEntries, deedEntries, mortgageEntries, parcelEntries}) ->
  # TODO: does this need to be discriminated further?  speculators can resell a property the same day they buy it with
  # TODO: simultaneous closings, how do we properly sort to account for that?
  # TODO: answer: by buyer/seller names, but we'll get to that later
  _promoteValues({taxEntries, deedEntries, mortgageEntries, parcelEntries, subtask, data_source_id})
  .then (tax) ->

    # we must use an existing transaction if there is one
    dbs.ensureTransaction transaction, 'main', (transaction) ->
      _updateDataCombined {subtask, id, data_source_id, transaction, tax}


module.exports = {
  finalizeDataTax
  finalizeDataDeed
  finalizeDataMortgage
  finalizeJoin
}
