_ = require 'lodash'
Promise = require 'bluebird'
dbs = require '../config/dbs'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
dataLoadHelpers = require './util.dataLoadHelpers'
logger = require('../config/logger').spawn('task:mls:agent')


_finalizeEntry = ({entry, subtask}) -> Promise.try ->
  entry.active = false
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
            active: false
          }
          .delete()
          .then () ->
            tables.finalized.agent({transaction})
            .insert(agent)


module.exports = {
  buildRecord
  finalizeData
}
