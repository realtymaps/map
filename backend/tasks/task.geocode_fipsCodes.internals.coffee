Promise = require 'bluebird'
through = require 'through2'
_ = require 'lodash'
logger = require('../config/logger').spawn('util:geocode:fipsCodes')
rawLogger = require('../config/logger').spawn('util:geocode:fipsCodes:loadRawData')
normalizeLogger = require('../config/logger').spawn('util:geocode:fipsCodes:normalize')
finalizeLogger = require('../config/logger').spawn('util:geocode:fipsCodes:finalize')
require '../extensions/logger'
require '../extensions/stream'
tables = require '../config/tables'
errors = require '../utils/errors/util.errors.fipsCodesLocality'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
dataLoadHelpers = require './util.dataLoadHelpers'
geocodeService = require '../services/service.google.geocode'

sqlHelpers = require '../utils/util.sql.helpers'
clone = require 'clone'
_ = require 'lodash'

safeColumnsFromRaw = [
  'state'
  'county'
  'code'
  'batch_id'
  'geometry'
  'geometry_center'
  'rm_raw_id'
]

_getFipsCodesToDefine = (entity) ->
  entity = clone entity

  #convenience mappings
  if entity.fips_code?
    entity.code = entity.fips_code
    delete entity.fips_code


  entity = _.pick entity, ['code', 'state', 'county']

  query = tables.lookup.fipsCodes()
  .where ->
    @whereNull 'geometry_raw'
    @orWhereNull 'geometry_center_raw'

  query = sqlHelpers.whereAndWhereIn(query, entity)
  logger.debug -> query.toString()
  query


_getSubtaskDefaults = (subtask) ->
  subtask.task_name ?= 'geocode_fipsCodes'
  subtask.data ?= {}
  subtask.data.dataType ?= 'google'
  subtask


loadRawData = (subtask = {}) ->
  _getSubtaskDefaults(subtask)
  subtask.batch_id ?= (Date.now()).toString(36)

  rawTableName = tables.temp.buildTableName(
    dataLoadHelpers.buildUniqueSubtaskName(subtask))

  rawLogger.debug -> subtask
  rawLogger.debug -> rawTableName
  # process.exit(0)

  dataLoadHistory =
    data_source_id: "#{subtask.task_name}"
    data_source_type: 'fipsCode'
    data_type: subtask.data.dataType
    batch_id: subtask.batch_id
    raw_table_name: rawTableName

  rawErrors = []

  geocodeService.localityObjectsStream(_getFipsCodesToDefine(subtask).stream())
  .then (jsonStream) ->

    dataLoadHelpers.manageRawJSONStream({
      tableName: rawTableName
      dataLoadHistory
      jsonStream
      column: 'json'
    })
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
    .catch (error) ->
      throw new SoftFail error.message
    .catch errors.Message, (error) ->
      rawErrors.push {error, dataLoadHistory, numRawRows: 0, fips_code: error.code}
    .catch errors.NoResults, (error) ->
      rawErrors.push {error, dataLoadHistory, numRawRows: 0, fips_code: error.code}
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'failed to raw fipsCode locality')
    .catch (error) ->
      throw new SoftFail(analyzeValue.getSimpleMessage(error))
  .then () ->
    rawLogger.debug -> "@@@@ rawErrors @@@@"
    rawLogger.debug -> rawErrors
    rawLogger.debug -> "done loadRawData"
    rawErrors

normalize = (subtask) ->
  _getSubtaskDefaults(subtask)

  normalizeLogger.debug -> "starting"
  normalizeLogger.debug -> subtask

  if !subtask?.batch_id?
    throw new Error('batch_id must be defined')

  rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask))

  saveToNormalDb = (entity, encoding, cb) ->

    safeEntity = _.pick(entity, safeColumnsFromRaw)

    safeEntity.batch_id = subtask.batch_id

    logger.debug -> "safeEntity"
    logger.debug -> safeEntity

    geometry_raw = tables.normalized.fipscodeLocality().raw("st_geomfromgeojson(?)", JSON.stringify safeEntity.geometry.geometry)
    geometry_center_raw = tables.normalized.fipscodeLocality().raw("st_geomfromgeojson(?)", JSON.stringify  safeEntity.geometry_center.geometry)

    logger.debugQuery(
      tables.normalized.fipscodeLocality()
      .insert(_.extend({}, safeEntity, {
        geometry_raw
        geometry_center_raw
      }))
    )
    .then () ->
      cb()
      return null #avoids runway promise error as this is NOT one
    .catch errors.NormalizeError, (error) ->
      tables.temp(subid: rawTableName)
      .where rm_raw_id: error.row.rm_raw_id
      .update rm_error_msg: error.message
    .catch (error) ->
      cb(error)

    return

  logger.debugQuery(
    tables.temp(subid: rawTableName)
    .whereNull('rm_error_msg')
  )
  .stream()
  .pipe(geocodeService.normalizeTransform)
  .pipe(through.obj(saveToNormalDb))
  .toPromise()
  .then () ->
    normalizeLogger.debug -> "finished"

finalize = (subtask) ->
  _getSubtaskDefaults(subtask)
  finalizeLogger.debug -> subtask
  finalizeLogger.debug -> 'starting'

  saveToFinalDb = (row, enc, cb) ->
    code = null

    Promise.try ->
      {code, state, county, geometry, geometry_center, geometry_raw, geometry_center_raw} = row

      finalizeLogger.debug -> "Attempting to Finalize: code: #{code}, county: #{county}, state: #{state}"

      tables.lookup.fipsCodes()
      .where({code})
      .update {
        geometry
        geometry_center
        geometry_raw
        geometry_center_raw
        # we could add state, and country and then we would get googles or whatever's services spelling (maybe corrections)
      }
    .then () ->
      finalizeLogger.debug -> "Done Finalizing code: #{code}"
      cb()
    .catch cb

  finalizeLogger.debug -> 'getting normalized data to finalize'

  logger.debugQuery(
    tables.normalized.fipscodeLocality()
    .where batch_id: subtask.batch_id
  )
  .stream()
  .pipe(through.obj saveToFinalDb)
  .toPromise()
  .then () ->
    finalizeLogger.debug -> "finished"


module.exports = {
  safeColumnsFromRaw
  loadRawData
  normalize
  finalize
}
