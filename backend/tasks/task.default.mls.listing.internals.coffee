_ = require 'lodash'
Promise = require 'bluebird'
dbs = require '../config/dbs'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'


_finalizeEntry = ({entries, subtask}) -> Promise.try ->
  index = 0
  for entry,i in entries
    if entry.status != 'discontinued'
      index = i
      break
  mainEntry = _.clone(entries[index])
  delete entries[index].shared_groups
  delete entries[index].subscriber_groups
  delete entries[index].hidden_fields
  delete entries[index].ungrouped_fields

  delete mainEntry.deleted
  delete mainEntry.hide_address
  delete mainEntry.hide_listing
  delete mainEntry.rm_inserted_time
  delete mainEntry.rm_modified_time
  # eventually, we should probably remove those columns and set them in config_mls instead
  delete mainEntry.photo_last_mod_time
  delete mainEntry.photo_id

  mainEntry.prior_entries = sqlHelpers.safeJsonArray(entries)
  mainEntry.address = sqlHelpers.safeJsonArray(mainEntry.address)
  mainEntry.owner_address = sqlHelpers.safeJsonArray(mainEntry.owner_address)
  mainEntry.change_history = sqlHelpers.safeJsonArray(mainEntry.change_history)
  mainEntry.update_source = subtask.task_name

  mainEntry.baths_total = mainEntry.baths?.filter

  mainEntry


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData) -> Promise.try () ->
# build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(base.address)
    hide_listing: base.hide_listing ? false
    hide_address: base.hide_address ? false
    shared_groups:
      general: normalizedData.general || []
      details: normalizedData.details || []
      listing: normalizedData.listing || []
      building: normalizedData.building || []
      dimensions: normalizedData.dimensions || []
      lot: normalizedData.lot || []
      location: normalizedData.location || []
      restrictions: normalizedData.restrictions || []
    subscriber_groups:
      contacts: normalizedData.contacts || []
      realtor: normalizedData.realtor || []
      sale: normalizedData.sale || []
    hidden_fields: dataLoadHelpers.getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
    deleted: null
  _.extend base, stats, data


finalizeData = ({subtask, id, data_source_id, finalizedParcel, transaction, delay}) ->
  delay ?= subtask.data?.delay || 100
  parcelHelpers = require './util.parcelHelpers'#delayed require due to circular dependency

  listingsPromise = tables.normalized.listing({transaction})
  .select('*')
  .where
    rm_property_id: id
    hide_listing: false
    data_source_id: data_source_id
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('hide_listing')
  .orderBy('data_source_id')
  .orderBy('deleted')
  .orderByRaw('close_date DESC NULLS FIRST')

  parcelPromise = if finalizedParcel?
    Promise.resolve([finalizedParcel])
  else
    parcelHelpers.getParcelsPromise {rm_property_id: id, transaction}

  Promise.join listingsPromise, parcelPromise, (listings=[], [parcel]=[]) ->

    if listings.length == 0
      # might happen if a singleton listing is changed to hidden during the day
      return dataLoadHelpers.markForDelete(id, data_source_id, subtask.batch_id, {transaction})

    _finalizeEntry({entries: listings, subtask})
    .then (listing) ->
      listing.data_source_type = 'mls'
      if parcel
        listing.geometry = parcel.geometry
        listing.geometry_raw = parcel.geometry_raw
        listing.geometry_center = parcel.geometry_center
        listing.geometry_center_raw = parcel.geometry_center_raw
      Promise.delay(delay)  #throttle for heroku's sake
      .then () ->
        # do owner name and zoning promotion logic
        if listing.owner_name? || listing.owner_name_2? || listing.zoning
          # keep previously-promoted values
          return false
        sqlHelpers.checkTableExists(tables.normalized.tax(subid: listing.fips_code))
      .then (checkPromotedValues) ->
        if !checkPromotedValues
          return
        # need to query the tax table to get values to promote
        tables.normalized.tax({subid: listing.fips_code, transaction})
        .select('promoted_values')
        .where
          rm_property_id: id
        .then (results=[]) ->
          if results[0]?.promoted_values
            # promote values into this listing
            _.extend(listing, results[0].promoted_values)

            # save back to the listing table to avoid making checks in the future
            tables.normalized.listing({transaction})
            .where
              data_source_id: listing.data_source_id
              data_source_uuid: listing.data_source_uuid
            .update(results[0].promoted_values)
      .then () ->
        dbs.ensureTransaction transaction, 'main', (transaction) ->
          tables.finalized.combined({transaction})
          .where
            rm_property_id: id
            data_source_id: data_source_id
          .delete()
          .then () ->
            tables.finalized.combined({transaction})
            .insert(listing)


module.exports = {
  buildRecord
  finalizeData
}
