_ = require 'lodash'
Promise = require 'bluebird'
dbs = require '../config/dbs'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'
logger = require('../config/logger').spawn('task:mls:agent')


_finalizeEntry = ({entry, subtask}) -> Promise.try ->
  delete entry.deleted
  delete entry.rm_inserted_time
  delete entry.rm_modified_time

  entry.change_history = sqlHelpers.safeJsonArray(entry.change_history)

  entry


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData, subtaskData) -> Promise.try () ->
# build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    ungrouped_fields: ungrouped
    deleted: null
    up_to_date: new Date(subtaskData.startTime)
  _.extend base, stats, data


finalizeData = ({subtask, data_source_uuid, data_source_id, transaction, delay}) ->
  delay ?= subtask.data?.delay || 100

  tables.normalized.agent({transaction})
  .select('*')
  .where({data_source_id, data_source_uuid})
  .whereNull('deleted')
  .orderBy('data_source_id')
  .orderBy('data_source_uuid')
  .then (agentResults) ->

    if agentResults.length != 1
      logger.warn("Duplicate (#{agentResults.length}) agent entries found for uuid: #{data_source_uuid}")

    _finalizeEntry({entry: agentResults[0], subtask})
    .then (agent) ->
      Promise.delay(delay)  #throttle for heroku's sake
      .then () ->
        dbs.ensureTransaction transaction, 'main', (transaction) ->
          tables.finalized.agent({transaction})
          .where {
            data_source_uuid
            data_source_id
          }
          .delete()
          .then () ->
            tables.finalized.agent({transaction})
            .insert(agent)


ensureNormalizedTable = (dataType, subid) ->
  tableQuery = tables.normalized[dataType]({subid})
  tableName = tableQuery.tableName
  sqlHelpers.checkTableExists(tableQuery)
  .then (tableAlreadyExists) ->
    if tableAlreadyExists
      return
    createTable = dbs.get('normalized').schema.createTable tableName, (table) ->
      """
    license_number integer NOT NULL,
    agent_status text NOT NULL,
    email text,
    full_name text NOT NULL,
    work_phone text,

"""
      table.timestamp('rm_inserted_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.timestamp('rm_modified_time', true).defaultTo(dbs.get('normalized').raw('now_utc()')).notNullable()
      table.text('data_source_id').notNullable()
      table.text('batch_id').notNullable().index()
      table.text('deleted')
      table.timestamp('up_to_date', true).notNullable()
      table.json('change_history').defaultTo('[]').notNullable()
      table.text('data_source_uuid').notNullable()
      table.integer('rm_raw_id').notNullable()
      table.text('inserted').notNullable()
      table.text('updated')
      table.json('ungrouped_fields')
      if dataType == 'tax'
        table.decimal('price', 13, 2)
        table.decimal('appraised_value', 13, 2)
        table.integer('bedrooms')
        table.json('baths')
        table.decimal('acres', 11, 3)
        table.integer('sqft_finished')
        table.json('year_built')
        table.text('zoning')
        table.text('property_type')
        table.text('legal_unit_number')
      else if dataType == 'deed'
        table.decimal('price', 13, 2)
        table.timestamp('close_date', true)
        table.text('property_type')
        table.text('legal_unit_number')
        table.text('seller_name')
        table.text('seller_name_2')
        table.text('document_type')
      else if dataType == 'mortgage'
        table.decimal('amount', 13, 2)
        table.timestamp('close_date', true)
        table.text('lender')
        table.text('term')
        table.text('financing_type')
        table.text('loan_type')
    .raw("CREATE UNIQUE INDEX ON #{tableName} (data_source_id, data_source_uuid)")
    .raw("CREATE TRIGGER update_rm_modified_time_#{tableName} BEFORE UPDATE ON #{tableName} FOR EACH ROW EXECUTE PROCEDURE update_rm_modified_time_column()")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, inserted)")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, deleted)")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, fips_code, deleted)")
    .raw("CREATE INDEX ON #{tableName} (data_source_id, updated)")
    if dataType == 'tax'
      createTable = createTable.raw("CREATE INDEX ON #{tableName} (rm_property_id, data_source_id, deleted, recording_date DESC NULLS LAST)")
      .raw("CREATE INDEX ON #{tableName} (rm_property_id)")
      .raw("CREATE INDEX ON #{tableName} (data_source_id, fips_code, parcel_id)")
    else
      createTable = createTable.raw("CREATE INDEX ON #{tableName} (rm_property_id, data_source_id, deleted, close_date DESC NULLS LAST)")
      .raw("CREATE INDEX ON #{tableName} (data_source_id, fips_code, data_source_uuid)")


module.exports = {
  buildRecord
  finalizeData
  ensureNormalizedTable
}
