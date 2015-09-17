_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled} = require './util.partiallyHandledError'
rets = require 'rets-client'
encryptor = require '../config/encryptor'
moment = require('moment')
logger = require '../config/logger'
require '../config/promisify'
memoize = require 'memoizee'


_getRetsClientInternal = (loginUrl, username, password, static_ip) ->
  Promise.try () ->
    new rets.Client
      loginUrl: loginUrl
      username: username
      password: encryptor.decrypt(password)
      proxyUrl: (if static_ip then process.env.PROXIMO_URL else null)
  .catch isUnhandled, (error) ->
    _getRetsClientInternal.delete(loginUrl, username, password, static_ip)
    throw new PartiallyHandledError(error, 'RETS client could not be created')
  .then (retsClient) ->
    logger.debug 'Logging in client ', loginUrl
    retsClient.login()
  .catch isUnhandled, (error) ->
    _getRetsClientInternal.delete(loginUrl, username, password, static_ip)
    if error.replyCode
      error = new Error("#{error.replyText} (#{error.replyCode})")
    throw new PartiallyHandledError(error, 'RETS login failed')
# reference counting memoize
_getRetsClientInternal = memoize _getRetsClientInternal,
  refCounter: true
  dispose: (promise) ->
    promise.then (retsClient) ->
      logger.debug 'Logging out client', retsClient?.urls?.Logout
      retsClient.logout()

_getRetsClient = (loginUrl, username, password, static_ip, handler) ->
  _getRetsClientInternal(loginUrl, username, password, static_ip)
  .then (retsClient) ->
    handler(retsClient)
  .finally () ->
    setTimeout (() -> _getRetsClientInternal.deleteRef(loginUrl, username, password, static_ip)), 60000

getDataDump = (mlsInfo, limit, minDate=0) ->
  _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip, (retsClient) ->
    if !mlsInfo.listing_data.queryTemplate || !mlsInfo.listing_data.field
      throw new PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config fields "Update Timestamp Column" and "Formatting")')
    momentThreshold = moment.utc(new Date(minDate)).format(mlsInfo.listing_data.queryTemplate.replace("__FIELD_NAME__", mlsInfo.listing_data.field))
    retsClient.search.query(mlsInfo.listing_data.db, mlsInfo.listing_data.table, momentThreshold, limit: limit)
    .then (results) ->
      retsClient.metadata.getTable(mlsInfo.listing_data.db, mlsInfo.listing_data.table)
      .catch isUnhandled, (error) ->
        if error.replyCode
          error = new Error("#{error.replyText} (#{error.replyCode})")
        throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
      .then (response) ->
        fieldMappings = {}
        for field in response.Fields
          if field.LongName.indexOf('.') != -1
            fieldMappings[field.LongName] = field.LongName.replace(/\./g, '')
        if _.isEmpty(fieldMappings)
          return results
        _.map results, (result) ->
          for oldName, newName of fieldMappings
            if oldName of result
              result[newName] = result[oldName]
              delete result[oldName]
  .catch isUnhandled, (error) ->
    if error.replyCode == "#{rets.replycode.NO_RECORDS_FOUND}"
      # code for 0 results, not really an error (DMQL is a clunky language)
      return []
    # TODO: else if error.replyCode == rets.replycode.MAX_RECORDS_EXCEEDED # "20208"
    if error.replyCode
      error = new Error("#{error.replyText} (#{error.replyCode})")
    # code for too many results, must manually paginate or something to get all the data
    throw new PartiallyHandledError(error, 'failed to query RETS system')

getDatabaseList = (serverInfo) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getResources()
    .catch (error) ->
      logger.error error.stack
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS databases')
    .then (response) ->
      _.map response.Resources, (r) ->
        _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']

getTableList = (serverInfo, databaseName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getClass(databaseName)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS tables')
    .then (response) ->
      _.map response.Classes, (r) ->
        _.pick r, ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']

getColumnList = (serverInfo, databaseName, tableName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getTable(databaseName, tableName)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (response) ->
      _.map response.Fields, (r) ->
        _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
    .then (fields) ->
      for field in fields
        field.LongName = field.LongName.replace(/\./g, '')
        

getLookupTypes = (serverInfo, databaseName, lookupId) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getLookupTypes(databaseName, lookupId)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS types')
    .then (response) ->
      response.LookupTypes


module.exports =
  getDatabaseList: getDatabaseList
  getTableList: getTableList
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
  getDataDump: getDataDump
