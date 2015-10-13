_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled, isCausedBy} = require './errors/util.error.partiallyHandledError'
rets = require 'rets-client'
encryptor = require '../config/encryptor'
moment = require('moment')
logger = require '../config/logger'
require '../config/promisify'
memoize = require 'memoizee'


_getRetsClientInternal = (loginUrl, username, password, static_ip, dummyCounter) ->
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
      throw new PartiallyHandledError(error, 'RETS login failed')
# reference counting memoize
_getRetsClientInternal = memoize.promise _getRetsClientInternal,
  refCounter: true
  primitive: true
  dispose: (retsClient) ->
    logger.debug 'Logging out client', retsClient?.urls?.Logout
    retsClient.logout()
# wrap into a reference-counting-buster
referenceBuster = {}
_getRetsClientInternalWrapper = (args...) -> _getRetsClientInternal(args..., referenceBuster[args.join('__')]||0)

_getRetsClient = (loginUrl, username, password, static_ip, handler) ->
  _getRetsClientInternalWrapper(loginUrl, username, password, static_ip)
  .then (retsClient) ->
    handler(retsClient)
    .catch isCausedBy(rets.RetsReplyError), (error) ->
      if error.replyTag in ["MISC_LOGIN_ERROR", "DUPLICATE_LOGIN_PROHIBITED"]
        referenceId = [loginUrl, username, password, static_ip].join('__')
        referenceBuster[referenceId] = (referenceBuster[referenceId] || 0) + 1
      throw error
    .catch isCausedBy(rets.RetsServerError), (error) ->
      if "#{error.httpStatus}" == "401"
        referenceId = [loginUrl, username, password, static_ip].join('__')
        referenceBuster[referenceId] = (referenceBuster[referenceId] || 0) + 1
      throw error
  .finally () ->
    setTimeout (() -> _getRetsClientInternal.deleteRef(loginUrl, username, password, static_ip)), 60000

getDataDump = (mlsInfo, limit, minDate=0) ->
  # this is now just a helper function that can ensure we get all results concatenated together
  getIterativeDataDump(mlsInfo, limit, minDate)
  .then (dumper) ->
    fullResults = null
    doIterations = () ->
      dumper.iterations.shift()
      .then (results) ->
        # takes the current set of results and saves them, iterates, and then waits on the promise for the next set
        if fullResults
          fullResults.concat(results)
        else
          fullResults = results
        if !dumper.iterations.length
          # nothing else is queued, so we're done
          results: fullResults
          columns: dumper.columns
        else
          # wait on the next item
          doIterations()
    # kick off the iterations
    doIterations()
    
getDatabaseList = (serverInfo) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getResources()
    .catch (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS databases')
    .then (response) ->
      _.map response.results, (r) ->
        _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']

getTableList = (serverInfo, databaseName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getClass(databaseName)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS tables')
    .then (response) ->
      _.map response.results, (r) ->
        _.pick r, ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']

getColumnList = (serverInfo, databaseName, tableName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getTable(databaseName, tableName)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (response) ->
      _.map response.results, (r) ->
        _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
    .then (fields) ->
      for field in fields
        field.LongName = field.LongName.replace(/[^a-zA-Z0-9]+/g, ' ').trim()
      fields
        

getLookupTypes = (serverInfo, databaseName, lookupId) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getLookupTypes(databaseName, lookupId)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS types')
    .then (response) ->
      response.results


getIterativeDataDump = (mlsInfo, limit, minDate=0) ->
  _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip, (retsClient) ->
    if !mlsInfo.listing_data.queryTemplate || !mlsInfo.listing_data.field
      throw new PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config fields "Update Timestamp Column" and "Formatting")')
    retsClient.metadata.getTable(mlsInfo.listing_data.db, mlsInfo.listing_data.table)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (columnData) ->
      fieldMappings = {}
      columns = []
      for field in columnData.results
        fieldMappings[field.SystemName] = field.LongName.replace(/[^a-zA-Z0-9]+/g, ' ').trim()
        columns.push(fieldMappings[field.SystemName])
      momentThreshold = moment.utc(new Date(minDate)).format(mlsInfo.listing_data.queryTemplate.replace("__FIELD_NAME__", mlsInfo.listing_data.field))
      options =
        limit: limit
        count: 0
      iterations = []
      total = 0
      timestamp = Date.now()
      errors = new Promise (resolve, reject) ->
        console.log("^^^^^^^^ #{total}: "+JSON.stringify(require('util').inspect(process.memoryUsage())))
        require('heapdump').writeSnapshot("/Users/joe/work/realtymaps/tmp/#{timestamp}.0.heapsnapshot")
        doIteration = () ->
          _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip, (retsClientIteration) ->
            retsClientIteration.search.query(mlsInfo.listing_data.db, mlsInfo.listing_data.table, momentThreshold, options, fieldMappings)
            .catch rets.RetsReplyError, (error) ->
              if error.replyTag == "NO_RECORDS_FOUND"
                # code for 0 results, not really an error (DMQL is a clunky language)
                return {results: []}
              throw error
            .then (searchResult) ->
              total += searchResult.results.length
              if total % 10000 == 0
                console.log("^^^^^^^^ #{total}: "+JSON.stringify(require('util').inspect(process.memoryUsage())))
                require('heapdump').writeSnapshot("/Users/joe/work/realtymaps/tmp/#{timestamp}.#{total}.heapsnapshot")
              if searchResult.maxRowsExceeded && (!limit || total < limit) 
                logger.debug "Partial results obtained (count: #{searchResult.results.length}, cumulative: #{total}), asking for more"
                options.offset = total
                if limit
                  options.limit = Math.min(limit, limit-total)
                iterations.push(doIteration())
              else
                logger.debug "Final result set obtained (count: #{searchResult.results.length}, cumulative: #{total})"
                resolve()
              return searchResult.results
            .catch (error) ->
              reject(error)
        iterations.push(doIteration())
      iterations: iterations
      columns: columns
      errors: errors
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, 'failed to query RETS system')


module.exports =
  getDatabaseList: getDatabaseList
  getTableList: getTableList
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
  getDataDump: getDataDump
  getIterativeDataDump: getIterativeDataDump
