_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled, isCausedBy} = require './errors/util.error.partiallyHandledError'
rets = require 'rets-client'
encryptor = require '../config/encryptor'
moment = require('moment')
logger = require '../config/logger'
require '../config/promisify'
memoize = require 'memoizee'
through2 = require 'through2'


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
    .catch (error) ->
      throw error
  .finally () ->
    setTimeout (() -> _getRetsClientInternal.deleteRef(loginUrl, username, password, static_ip)), 60000
    
getDatabaseList = (serverInfo) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getResources()
    .catch (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS databases')
    .then (response) ->
      _.map response.results[0].metadata, (r) ->
        _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']

getTableList = (serverInfo, databaseName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getClass(databaseName)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS tables')
    .then (response) ->
      _.map response.results[0].metadata, (r) ->
        _.pick r, ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']

getColumnList = (serverInfo, databaseName, tableName) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getTable(databaseName, tableName)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (response) ->
      _.map response.results[0].metadata, (r) ->
        _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
    .then (fields) ->
      reverseMappings =
        dummy1: "dummy1"
        dummy2: "dummy2"
      for field in fields
        field.LongName = field.LongName.replace(/\./g, '').trim()
        # handle LongName collisions
        if reverseMappings[field.LongName]?
          i=2
          baseName = field.LongName
          while reverseMappings["#{baseName} (#{i})"]?
            i++
          field.LongName = "#{baseName} (#{i})"
        reverseMappings[field.LongName] = field.SystemName
      fields


getLookupTypes = (serverInfo, databaseName, lookupId) ->
  _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
    retsClient.metadata.getLookupTypes(databaseName, lookupId)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS types')
    .then (response) ->
      response.results[0].metadata


getDataStream = (mlsInfo, limit, minDate=0) ->
  _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip, (retsClient) ->
    if !mlsInfo.listing_data.queryTemplate || !mlsInfo.listing_data.field
      throw new PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config fields "Update Timestamp Column" and "Formatting")')
    retsClient.metadata.getTable(mlsInfo.listing_data.db, mlsInfo.listing_data.table)
    .catch isUnhandled, (error) ->
      throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (columnData) ->
      fieldMappings = {}
      reverseMappings = {}
      for field in columnData.results[0].metadata
        fieldMappings[field.SystemName] = field.LongName.replace(/\./g, '').trim()
        # handle LongName collisions
        if reverseMappings[fieldMappings[field.SystemName]]?
          i=2
          baseName = fieldMappings[field.SystemName]
          while reverseMappings["#{baseName} (#{i})"]?
            i++
          fieldMappings[field.SystemName] = "#{baseName} (#{i})"
        reverseMappings[fieldMappings[field.SystemName]] = field.SystemName
      momentThreshold = moment.utc(new Date(minDate)).format(mlsInfo.listing_data.queryTemplate.replace("__FIELD_NAME__", mlsInfo.listing_data.field))
      options =
        limit: limit
        count: 0
      total = 0
      subcount = 0
      columns = null
      delimiter = null
      done = false
      retsStream = null
      finish = (that, error) ->
        retsStream.unpipe(resultStream)
        done = true
        if error
          that.push(type: 'error', payload: error)
        resultStream.end()
      streamIteration = () ->
        new Promise (resolve, reject) ->
          resolved = false
          _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip, (retsClientIteration) ->
            new Promise (resolve2, reject2) ->
              retsStream = retsClientIteration.search.stream.query(mlsInfo.listing_data.db, mlsInfo.listing_data.table, momentThreshold, options, true)
              retsStream.pipe(resultStream, end: false)
              retsStream.on 'end', resolve2
              resolved = true
              resolve(retsStream)
          .catch (error) ->
            if !resolved
              resolved = true
              reject(error)
      started = false
      resultStream = through2.obj (event, encoding, callback) ->
        if !started
          started = true
        if done
          return
        switch event.type
          when 'delimiter'
            if !delimiter
              delimiter = event.payload
              @push(event)
            else if event.payload != delimiter
              finish(this, new Error('rets delimiter changed during iteration'))
            callback()
          when 'columns'
            if !columns
              columns = event.payload
              columnList = event.payload.split(delimiter)[1..-2]
              for column,i in columnList
                if fieldMappings[column]?
                  columnList[i] = fieldMappings[column]
              @push(type: 'columns', payload: columnList)
            else if event.payload != columns
              finish(this, new Error('rets columns changed during iteration'))
            callback()
          when 'data'
            event.payload = event.payload[1..event.payload.lastIndexOf(delimiter)-1]
            @push(event)
            callback()
          when 'done'
            total += event.payload.rowsReceived
            if event.payload.maxRowsExceeded && (!limit || total < limit)
              options.offset = total
              if limit
                options.limit = limit-total
              streamIteration()
              .catch (err) =>
                finish(this, err)
              .then () ->
                callback()
            else
              @push(type: 'done', payload: total)
              resultStream.end()
              callback()
          when 'error'
            if event.payload instanceof rets.RetsReplyError && event.payload.replyTag == "NO_RECORDS_FOUND" && total > 0
              # code for 0 results, not really an error (DMQL is a clunky language)
              @push(type: 'done', payload: total)
              resultStream.end()
            else
              finish(this, event.payload)
            callback()
          else
            callback()
      streamIteration()
      .then () ->
        resultStream
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, 'failed to query RETS system')


module.exports =
  getDatabaseList: getDatabaseList
  getTableList: getTableList
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
  getDataStream: getDataStream
