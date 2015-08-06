_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require './util.partiallyHandledError'
rets = require 'rets-client'
Encryptor = require './util.encryptor'
moment = require('moment')
copyStream = require 'pg-copy-streams'
from = require 'from'
utilStreams = require './util.streams'
dbs = require '../config/dbs'
config = require '../config/config'
taskHelpers = require './tasks/util.taskHelpers'
logger = require '../config/logger'
jobQueue = require './util.jobQueue'
validation = require './util.validation'
require '../config/promisify'
memoize = require 'memoizee'
vm = require 'vm'
tables = require '../config/tables'
validatorBuilder = require '../../common/utils/util.validatorBuilder'
sqlHelpers = require './util.sql.helpers'
util = require 'util'


encryptor = new Encryptor(cipherKey: config.ENCRYPTION_AT_REST)


_getRetsClient = memoize(
  (loginUrl, username, password, static_ip) ->
    Promise.try () ->
      new rets.Client
        loginUrl: loginUrl
        username: username
        password: encryptor.decrypt(password)
        proxyUrl: (if static_ip then process.env.PROXIMO_URL else null)
    .catch isUnhandled, (error) ->
      _getRetsClient.delete(loginUrl, username, password, static_ip)
      throw new PartiallyHandledError(error, "RETS client could not be created")
    .then (retsClient) ->
      logger.info 'Logging in client ', loginUrl
      retsClient.login()
      .catch isUnhandled, (error) ->
        _getRetsClient.delete(loginUrl, username, password, static_ip)
        if error.replyCode
          error = new Error("#{error.replyText} (#{error.replyCode})")
        throw new PartiallyHandledError(error, "RETS login failed")
  ,
    maxAge: 60000
    dispose: (promise) ->
      promise.then (retsClient) ->
        logger.info 'Logging out client', retsClient?.urls?.Logout
        retsClient.logout()
)

getDataDump = (mlsInfo, limit=1000) ->
  _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip
  .then (retsClient) ->
    if !mlsInfo.main_property_data.queryTemplate || !mlsInfo.main_property_data.field
      throw new PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config fields "Update Timestamp Column" and "Formatting")')
    momentThreshold = moment.utc(new Date(0)).format(mlsInfo.main_property_data.queryTemplate.replace("__FIELD_NAME__", mlsInfo.main_property_data.field))
    retsClient.search.query(mlsInfo.main_property_data.db, mlsInfo.main_property_data.table, momentThreshold, limit: limit)
  .catch isUnhandled, (error) ->
    if error.replyCode == "#{rets.replycode.NO_RECORDS_FOUND}"
      # code for 0 results, not really an error (DMQL is a clunky language)
      return []
    # TODO: else if error.replyCode == rets.replycode.MAX_RECORDS_EXCEEDED # "20208"
    # code for too many results, must manually paginate or something to get all the data
    throw new PartiallyHandledError(error, "failed to query RETS system")

getDatabaseList = (serverInfo) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip
  .then (retsClient) ->
    retsClient.metadata.getResources()
    .catch (error) ->
      logger.error error.stack
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, "Failed to retrieve RETS databases")
    .then (response) ->
      _.map response.Resources, (r) ->
        _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']

getTableList = (serverInfo, databaseName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip
  .then (retsClient) ->
    retsClient.metadata.getClass(databaseName)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, "Failed to retrieve RETS tables")
    .then (response) ->
      _.map response.Classes, (r) ->
        _.pick r, ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']

getColumnList = (serverInfo, databaseName, tableName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip
  .then (retsClient) ->
    retsClient.metadata.getTable(databaseName, tableName)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(new Error("#{error.replyText} (#{error.replyCode})"), "Failed to retrieve RETS columns")
    .then (response) ->
      _.map response.Fields, (r) ->
        _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']

getLookupTypes = (serverInfo, databaseName, lookupId) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip
  .then (retsClient) ->
    retsClient.metadata.getLookupTypes(databaseName, lookupId)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(new Error("#{error.replyText} (#{error.replyCode})"), "Failed to retrieve RETS types")
    .then (response) ->
      response.LookupTypes


module.exports =
  getDatabaseList: getDatabaseList
  getTableList: getTableList
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
  getDataDump: getDataDump
