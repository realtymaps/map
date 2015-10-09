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
      error = new Error("#{error.replyText} (#{error.replyCode}: #{error.replyTag})")
    throw new PartiallyHandledError(error, 'RETS login failed')
# reference counting memoize
_getRetsClientInternal = memoize _getRetsClientInternal,
  refCounter: true
  primitive: true
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

getDataDump = (mlsInfo, limit, minDate=0, oneIterationOnly=false) ->
  # this is now just a helper function that can ensure we get all results concatenated together
  getIterativeDataDump(mlsInfo, limit, minDate, oneIterationOnly)
  .then (dumper) ->
    fullResults = null
    i=0
    _doIterations = (results) ->
      # takes the current set of results and saves them, iterates, and then waits on the promise for the next set
      if fullResults
        fullResults.concat(results)
      else
        fullResults = results
      i++
      if i >= dumper.iterations.length
        # nothing else is queued, so we're done
        results: fullResults
        columns: dumper.columns
      else
        # wait on the next item
        dumper.iterations[i]
        .then _doIterations
    # kick off the iteration
    dumper.iterations[0]
    .then _doIterations
    
getDatabaseList = (serverInfo) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getResources()
    .catch (error) ->
      logger.error error.stack
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode}: #{error.replyTag})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS databases')
    .then (response) ->
      _.map response.results, (r) ->
        _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']

getTableList = (serverInfo, databaseName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getClass(databaseName)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode}: #{error.replyTag})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS tables')
    .then (response) ->
      _.map response.results, (r) ->
        _.pick r, ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']

getColumnList = (serverInfo, databaseName, tableName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getTable(databaseName, tableName)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode}: #{error.replyTag})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (response) ->
      _.map response.results, (r) ->
        _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
    .then (fields) ->
      for field in fields
        field.LongName = field.LongName.replace(/\./g, '')
      fields
        

getLookupTypes = (serverInfo, databaseName, lookupId) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getLookupTypes(databaseName, lookupId)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode}: #{error.replyTag})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS types')
    .then (response) ->
      response.results


getIterativeDataDump = (mlsInfo, limit, minDate=0, oneIterationOnly=false) ->
  _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip, (retsClient) ->
    if !mlsInfo.listing_data.queryTemplate || !mlsInfo.listing_data.field
      throw new PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config fields "Update Timestamp Column" and "Formatting")')
    fieldMappings = {}
    retsClient.metadata.getTable(mlsInfo.listing_data.db, mlsInfo.listing_data.table)
    .catch isUnhandled, (error) ->
      if error.replyCode
        error = new Error("#{error.replyText} (#{error.replyCode}: #{error.replyTag})")
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (columnData) ->
      for field in columnData.results
        if field.LongName.indexOf('.') != -1
          fieldMappings[field.LongName] = field.LongName.replace(/\./g, '')
      momentThreshold = moment.utc(new Date(minDate)).format(mlsInfo.listing_data.queryTemplate.replace("__FIELD_NAME__", mlsInfo.listing_data.field))
      options =
        limit: limit
        count: 0
      iterations = []
      doIteration = () ->
        retsClient.search.query(mlsInfo.listing_data.db, mlsInfo.listing_data.table, momentThreshold, options)
        .then (searchResult) ->
          if _.isEmpty(fieldMappings)
            return searchResult.results
          for result in searchResult.results
            for oldName, newName of fieldMappings
              if oldName of result
                result[newName] = result[oldName]
                delete result[oldName]
          return searchResult
        .catch isUnhandled, (error) ->
          if error.replyCode == "#{rets.replycode.NO_RECORDS_FOUND}"
            # code for 0 results, not really an error (DMQL is a clunky language)
            return {results: []}
          throw error
        .then (processedResult) ->
          if processedResult.maxRowsExceeded && !oneIterationOnly
            logger.debug "Partial results obtained (count: #{processedResult.results.length}), asking for more"
            options.offset = (options.offset ? 0) + processedResult.results.length
            iterations.push(doIteration())
          else
            logger.debug "Final result set obtained (count: #{processedResult.results.length})"
          return processedResult.results
      iterations.push(doIteration())
      iterations: iterations
      columns: columnData
  .catch isUnhandled, (error) ->
    if error.replyCode
      error = new Error("#{error.replyText} (#{error.replyCode}: #{error.replyTag})")
    throw new PartiallyHandledError(error, 'failed to query RETS system')


module.exports =
  getDatabaseList: getDatabaseList
  getTableList: getTableList
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
  getDataDump: getDataDump
  getIterativeDataDump: getIterativeDataDump
