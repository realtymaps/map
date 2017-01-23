_ = require 'lodash'
Promise = require 'bluebird'
dbs = require '../config/dbs'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'


_finalizeEntry = ({entries, subtask, data_source_id}) -> Promise.try ->
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
  mainEntry.data_source_id = data_source_id

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

  listingsPromise = tables.normalized.listing({subid: data_source_id})  # no transaction -- normalized db
  .select('*')
  .where
    rm_property_id: id
    hide_listing: false
  .whereNull('deleted')
  .orderBy('rm_property_id')
  .orderBy('hide_listing')
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

    _finalizeEntry({entries: listings, subtask, data_source_id})
    .then (listing) ->
      listing.data_source_type = 'mls'
      if parcel
        listing.geometry = parcel.geometry
        listing.geometry_raw = parcel.geometry_raw
        listing.geometry_center = parcel.geometry_center
        listing.geometry_center_raw = parcel.geometry_center_raw
      Promise.delay(delay)  #throttle for heroku's sake
      .then () ->
        # do county data promotion logic
        if listing.zoning
          # if we have zoning info already, don't bother promoting
          return false
        sqlHelpers.checkTableExists(tables.normalized.tax(subid: ['blackknight', listing.fips_code]))
      .then (checkPromotedValues) ->
        if !checkPromotedValues
          return
        # need to query the tax table to get values to promote
        tables.normalized.tax({subid: ['blackknight', listing.fips_code]})  # no transaction -- normalized db
        .select('zoning')
        .where
          rm_property_id: id
        .then (results=[]) ->
          if results[0]?.zoning
            # promote values into this listing
            _.extend(listing, results[0])

            # save back to the listing table to avoid making checks in the future
            tables.normalized.listing({subid: data_source_id})  # no transaction -- normalized db
            .where(data_source_uuid: listing.data_source_uuid)
            .update(results[0])
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


ensureNormalizedTable = (subid) ->
  tableQuery = tables.normalized.listing({subid})
  tableName = tableQuery.tableName
  sqlHelpers.checkTableExists(tableQuery)
  .then (tableAlreadyExists) ->
    if tableAlreadyExists
      return
    dbs.get('normalized').schema.createTable tableName, (table) ->
      table.timestamp('rm_inserted_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.timestamp('rm_modified_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.text('batch_id').notNullable().index()
      table.text('deleted')
      table.timestamp('up_to_date', true).notNullable()
      table.json('change_history').defaultTo('[]').notNullable()
      table.text('data_source_uuid').notNullable()
      table.text('rm_property_id').notNullable()
      table.integer('fips_code').notNullable()
      table.text('parcel_id').notNullable()
      table.json('address')
      table.decimal('price', 13, 2)
      table.integer('days_on_market')
      table.integer('bedrooms')
      table.decimal('acres', 11, 3)
      table.integer('sqft_finished')
      table.text('status').notNullable()
      table.text('status_display').notNullable()
      table.integer('rm_raw_id').notNullable()
      table.text('inserted').notNullable()
      table.text('updated')
      table.json('shared_groups').notNullable()
      table.json('subscriber_groups').notNullable()
      table.json('hidden_fields').notNullable()
      table.json('ungrouped_fields')
      table.timestamp('close_date', true)
      table.boolean('hide_listing').notNullable()
      table.timestamp('discontinued_date', true)
      table.boolean('hide_address').notNullable()
      table.json('year_built')
      table.json('baths')
      table.text('zoning')
      table.text('property_type')
      table.text('description')
      table.decimal('original_price', 13, 2)
      table.text('photo_id')
      table.timestamp('photo_last_mod_time', true)
      table.timestamp('creation_date', true)
      table.integer('days_on_market_cumulative')
      table.integer('days_on_market_filter')
    .raw("CREATE UNIQUE INDEX ON ?? (data_source_uuid)", [tableName])
    .raw("CREATE TRIGGER ?? BEFORE UPDATE ON ?? FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column()", ["update_rm_modified_time_#{tableName}",tableName])
    .raw("CREATE INDEX ON ?? (inserted)", [tableName])
    .raw("CREATE INDEX ON ?? (deleted)", [tableName])
    .raw("CREATE INDEX ON ?? (deleted, data_source_uuid)", [tableName])
    .raw("CREATE INDEX ON ?? (updated)", [tableName])
    .raw("CREATE INDEX ON ?? (batch_id)", [tableName])
    .raw("CREATE INDEX ON ?? (rm_property_id, hide_listing, deleted, close_date DESC)", [tableName])


module.exports = {
  buildRecord
  finalizeData
  ensureNormalizedTable
}
