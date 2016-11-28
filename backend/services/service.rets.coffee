_ = require 'lodash'
Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
rets = require 'rets-client'
logger = require('../config/logger').spawn('rets')
require '../config/promisify'
through2 = require 'through2'
internals = require './service.rets.internals'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'
util = require 'util'


getSystemData = (mlsId) ->
  logger.spawn(mlsId).debug () -> "getting system data for #{mlsId}"
  internals.getRetsClient mlsId, (retsClient) ->
    retsClient.metadata.getSystem()

getDatabaseList = (mlsId, opts={}) ->
  logger.spawn(mlsId).debug () -> "getting database list for #{mlsId}"
  restrictFields = opts.restrictFields ? ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']
  internals.getRetsClient mlsId, (retsClient) ->
    retsClient.metadata.getResources()
    .catch (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS databases')
    .then (response) ->
      result = response.results[0].metadata
      if !restrictFields
        return result
      _.map result, (r) ->
        _.pick(r, restrictFields)

getObjectList = (mlsId, opts={}) ->
  logger.spawn(mlsId).debug () -> "getting object list for #{mlsId}"
  restrictFields = opts.restrictFields ? ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']
  internals.getRetsClient mlsId, (retsClient) ->
    retsClient.metadata.getObject('0')
    .catch (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS objects')
    .then (response) ->
      result = response.results[0].metadata
      if !restrictFields
        return result
      _.map result, (r) ->
        _.pick(r, restrictFields)

getTableList = (mlsId, databaseName, opts={}) ->
  logger.spawn(mlsId).debug () -> "getting table list for #{mlsId}/#{databaseName}"
  restrictFields = opts.restrictFields ? ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']
  internals.getRetsClient mlsId, (retsClient) ->
    retsClient.metadata.getClass(databaseName)
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS tables')
    .then (response) ->
      result = response.results[0].metadata
      if !restrictFields
        return result
      _.map result, (r) ->
        _.pick(r, restrictFields)

getColumnList = (mlsId, databaseName, tableName, opts={}) ->
  logger.spawn(mlsId).debug () -> "getting column list for #{mlsId}/#{databaseName}/#{tableName}"
  restrictFields = opts.restrictFields ? ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
  internals.getRetsClient mlsId, (retsClient) ->
    retsClient.metadata.getTable(databaseName, tableName)
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS columns')
    .then (response) ->
      result = response.results[0].metadata
      if restrictFields && restrictFields.indexOf('LongName') == -1
        return result
      reverseMappings = {}
      for field in result
        field.LongName = field.LongName.replace(/\./g, '').trim()
        # handle LongName collisions
        if reverseMappings[field.LongName]?
          i=2
          baseName = field.LongName
          while reverseMappings["#{baseName} (#{i})"]?
            i++
          field.LongName = "#{baseName} (#{i})"
        reverseMappings[field.LongName] = field.SystemName
      result
    .then (fields) ->
      if !restrictFields
        return fields
      _.map fields, (r) ->
        _.pick(r, restrictFields)

getLookupTypes = (mlsId, databaseName, lookupId) ->
  logger.spawn(mlsId).debug () -> "getting lookup for #{mlsId}/#{databaseName}/#{lookupId}"
  internals.getRetsClient mlsId, (retsClient) ->
    retsClient.metadata.getLookupTypes(databaseName, lookupId)
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS types')
    .then (response) ->
      response.results[0].metadata


getDataStream = (mlsId, dataType, opts={}) ->
  logger.spawn(mlsId).debug () -> "getting data stream for #{mlsId}/#{dataType}: #{JSON.stringify(opts)}"
  internals.getRetsClient mlsId, (retsClient, mlsInfo) ->
    schemaInfo = mlsInfo["#{dataType}_data"]
    if !schemaInfo.field
      throw new errorHandlingUtils.PartiallyHandledError("Cannot query without a timestamp field to filter (check MLS config field 'Update Timestamp Column' for #{mlsId}/#{dataType})")
    offsetPromise = Promise.try () ->
      # determine time zone offset so we can use the correct date if server doesn't support a full DateTime
      if schemaInfo.field_type == 'DateTime'
        return 0
      getSystemData(mlsId)
      .then (systemData) ->
        return parseInt(systemData.TimeZoneOffset) || 0
    Promise.join offsetPromise, getColumnList(mlsId, schemaInfo.db, schemaInfo.table), (utcOffset, columnData) ->
      fieldMappings = {}
      for field in columnData
        fieldMappings[field.SystemName] = field.LongName
      total = 0
      overlap = 0
      lastId = null
      currentPayload = null
      found = null
      counter = 0
      debugCount = 0
      searchQuery = internals.buildSearchQuery(schemaInfo, utcOffset, opts)
      searchOptions =
        count: 0
      _.extend(searchOptions, opts.searchOptions)
      baseOffset = opts.searchOptions.offset ? 0
      fullLimit = opts.searchOptions.limit
      if opts.subLimit
        if searchOptions.limit
          searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)
        else
          searchOptions.limit = opts.subLimit
      logger.spawn(mlsId).debug () -> "getDataStream prepped for #{mlsId}/#{dataType}: #{searchQuery} / searchOptions: #{JSON.stringify(searchOptions)}, utcOffset: #{utcOffset}"

      columns = null
      uuidColumn = null
      delimiter = null
      done = false
      retsStream = null
      finish = (that, error) ->
        logger.spawn(mlsId).debug () -> "getDataStream finished for #{mlsId}/#{dataType}, error: #{analyzeValue.getFullDetails(error)}"
        retsStream.unpipe(resultStream)
        done = true
        if error
          that.push(type: 'error', payload: error)
        else
          that.push(type: 'done', payload: total)
        resultStream.end()
      streamIteration = () ->
        logger.spawn(mlsId).debug () -> "getDataStream iteration for #{mlsId}/#{dataType}: #{searchQuery} (limit: #{searchOptions.limit}, offset: #{searchOptions.offset}, overlap: #{overlap})"
        found = null
        counter = 0
        new Promise (resolve, reject) ->
          resolved = false
          internals.getRetsClient mlsId, (retsClientIteration) ->
            new Promise (resolve2, reject2) ->
              retsStream = retsClientIteration.search.stream.query(schemaInfo.db, schemaInfo.table, searchQuery, searchOptions, true)
              retsStream.pipe(resultStream, end: false)
              retsStream.on 'end', resolve2
              resolved = true
              resolve(retsStream)
          .catch (error) ->
            if !resolved
              resolved = true
              reject(error)
      resultStreamLogger = logger.spawn(mlsId).spawn('resultStream')
      resultStream = through2.obj (event, encoding, callback) ->
        try
          if done
            resultStreamLogger.debug () -> "*****  |  already done, skipping: #{event.type}: #{JSON.stringify(event.payload)}"
            return
          switch event.type
            when 'data'
              event.payload = event.payload[1..event.payload.lastIndexOf(delimiter)-1]
              if !lastId || found
                if opts.uuidField
                  currentPayload = event.payload
                @push(event)
              else
                if lastId == event.payload.split(delimiter)[uuidColumn]
                  found = counter
                else
                  counter++
              debugCount++
              if debugCount%5000 == 0
                resultStreamLogger.debug () -> "EVENT  |  data: {lines: #{debugCount}, buffer: #{resultStream._readableState.length}/#{resultStream._readableState.highWaterMark}}"
              callback()
            when 'delimiter'
              resultStreamLogger.debug () -> "EVENT  |  #{event.type}: #{JSON.stringify(event.payload)}"
              if !delimiter
                delimiter = event.payload
                @push(event)
              else if event.payload != delimiter
                finish(this, new Error('rets delimiter changed during iteration'))
              callback()
            when 'columns'
              resultStreamLogger.debug () -> "EVENT  |  #{event.type}"
              if !columns
                columns = event.payload
                columnList = event.payload.split(delimiter)[1..-2]
                for column,i in columnList
                  if opts.uuidField && column == opts.uuidField
                    uuidColumn = i
                  if fieldMappings[column]?
                    columnList[i] = fieldMappings[column]
                if opts.uuidField && !uuidColumn?
                  finish(this, new Error('failed to locate specificed UUID column'))
                @push(type: 'columns', payload: columnList)
              else if event.payload != columns
                finish(this, new Error('rets columns changed during iteration'))
              callback()
            when 'done'
              resultStreamLogger.debug () -> "EVENT  |  #{event.type}: #{JSON.stringify(event.payload)} / {lines: #{debugCount}, buffer: #{resultStream._readableState.length}/#{resultStream._readableState.highWaterMark}}"
              debugCount = 0
              if lastId && !found
                finish(this, new SoftFail('failed to locate RETS overlap record'))
                callback()
              else
                received = event.payload.rowsReceived
                if lastId
                  received -= found+1
                total += received
                if opts.uuidField?
                  if mlsInfo.verify_overlap
                    lastId = currentPayload.split(delimiter)[uuidColumn]
                  if !overlap
                    overlap = Math.max(10, Math.floor(event.payload.rowsReceived*0.001))  # 0.1% of the allowed result size, min 10
                    if !mlsInfo.verify_overlap
                      overlap *= 2  # if we aren't verifying, use a bigger overlap for safety
                if event.payload.maxRowsExceeded && (!fullLimit || total < fullLimit)
                  searchOptions.offset = baseOffset+total-overlap
                  if fullLimit
                    searchOptions.limit = fullLimit - (searchOptions.offset - baseOffset)
                    if opts.subLimit
                      searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)
                  streamIteration()
                  .catch (err) =>
                    finish(this, err)
                  .then () ->
                    callback()
                else
                  finish(this)
                  callback()
            when 'error'
              resultStreamLogger.debug () -> "EVENT  |  data: {lines: #{debugCount}}"
              resultStreamLogger.debug () -> "EVENT  |  #{event.type}: #{JSON.stringify(event.payload)}"
              if event.payload instanceof rets.RetsReplyError && event.payload.replyTag == "NO_RECORDS_FOUND" && total > 0
                resultStreamLogger.debug () -> "       |  ignoring, not a real error"
                # code for 0 results, not really an error (DMQL is a clunky language)
                finish(this)
              else
                finish(this, event.payload)
              callback()
            else
              resultStreamLogger.debug () -> "EVENT  |  #{event.type}: #{JSON.stringify(event.payload)}"
              callback()
        catch error
          resultStreamLogger.debug () -> "EVENT  |  data: {lines: #{debugCount}, buffer: #{resultStream._readableState.length}/#{resultStream._readableState.highWaterMark}}"
          resultStreamLogger.debug () -> "*****  |  error in catch block!!!"
          finish(this, error)
          callback()
      streamIteration()
      .then () ->
        logger.spawn(mlsId).debug () -> "getDataStream handing off resultStream for #{mlsId}/#{dataType}"
        resultStream
  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to query RETS system')


getDataChunks = (mlsId, dataType, opts, handler) ->
  if typeof(handler) == 'undefined'
    # syntactic sugar to allow a default opts value, but leave the handler at the end of the param list
    handler = opts
    opts = {}
  internals.getRetsClient mlsId, (retsClient, mlsInfo) ->
    # override mls schemaInfo with optional `schemaInfo` if provided
    if !_.isEmpty(opts?.schemaInfo)
      schemaInfo = opts.schemaInfo
    else
      schemaInfo = mlsInfo["#{dataType}_data"]

    if !schemaInfo.field
      throw new errorHandlingUtils.PartiallyHandledError('Cannot query without a timestamp field to filter (check MLS config field "Update Timestamp Column")')
    Promise.try () ->
      logger.spawn(mlsId).debug () -> "determining RETS time zone offset for #{mlsId}"
      if schemaInfo.field_type != 'Date'
        return 0
      getSystemData(mlsId)
      .then (systemData) ->
        return parseInt(systemData.TimeZoneOffset) || 0
    .then (utcOffset) ->
      total = 0
      overlap = 0
      lastId = null
      searchQuery = internals.buildSearchQuery(schemaInfo, utcOffset, opts)
      searchOptions =
        count: 0
      _.extend(searchOptions, opts.searchOptions)
      baseOffset = opts.searchOptions.offset ? 0
      fullLimit = opts.searchOptions.limit
      if opts.subLimit
        if searchOptions.limit
          searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)
        else
          searchOptions.limit = opts.subLimit

      searchIteration = () ->
        logger.spawn(mlsId).debug () -> "getting data chunk for #{mlsId}: #{searchQuery} (offset: #{searchOptions.offset})"
        internals.getRetsClient mlsId, (retsClientIteration) ->
          retsClientIteration.search.query(schemaInfo.db, schemaInfo.table, searchQuery, searchOptions)
          .then (response) ->
            if lastId?
              found = null
              for listing,i in response.results
                if listing[opts.uuidField] == lastId
                  found = i
                  break
              if !found?
                throw new SoftFail('failed to locate RETS overlap record')
              results = response.results.slice(found+1)
              if results.length == 0
                throw new SoftFail('no new results found in interation')
            else
              results = response.results
            if opts.uuidField?
              if mlsInfo.verify_overlap
                lastId = results[results.length-1][opts.uuidField]
              if !overlap
                overlap = Math.max(10, Math.floor(results.length*0.001))  # 0.1% of the allowed result size, min 10
                if !mlsInfo.verify_overlap
                  overlap *= 2  # if we aren't verifying, use a bigger overlap for safety
            total += results.length
            if response.maxRowsExceeded && (!fullLimit || total < fullLimit)
              searchOptions.offset = baseOffset+total-overlap
              if fullLimit
                searchOptions.limit = fullLimit - (searchOptions.offset - baseOffset)
                if opts.subLimit
                  searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)
              handlerPromise = Promise.try () ->
                handler(results)
              .catch errorHandlingUtils.isUnhandled, (err) ->
                throw new errorHandlingUtils.PartiallyHandledError(err, 'error in chunk handler')
              nextIterationPromise = searchIteration()
              Promise.join handlerPromise, nextIterationPromise, () ->  # no-op
            else
              handler(results)
          .then () ->
            return total
          .catch rets.RetsReplyError, (err) ->
            if err.replyTag == "NO_RECORDS_FOUND"
              # code for 0 results, not really an error (DMQL is a clunky language)
              return total
            else
              throw err

      searchIteration()

  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to query RETS system')


getPhotosObject = ({mlsId, databaseName, photoIds, objectsOpts, photoType}) ->
  objectsOpts ?= alwaysGroupObjects: true, ObjectData: '*'
  photoType ?= 'Photo'

  internals.getRetsClient mlsId, (retsClient) ->
    retsClient.objects.stream.getObjects(databaseName, photoType, photoIds, objectsOpts)
    .catch errorHandlingUtils.isUnhandled, (err) ->
      logger.spawn(mlsId).debug("error from service.rets#retsClient.objects.stream.getObjects: #{analyzeValue.getFullDetails(err)}")
      throw err
  .catch errorHandlingUtils.isUnhandled, (err) ->
    logger.spawn(mlsId).debug("error from service.rets#internals.getRetsClient: #{analyzeValue.getFullDetails(err)}")
    throw err


module.exports = {
  getSystemData
  getDatabaseList
  getTableList
  getColumnList
  getLookupTypes
  getDataStream
  getDataChunks
  getPhotosObject
  getObjectList
  isMaybeTransientRetsError: internals.isMaybeTransientRetsError
  RetsError: rets.RetsError
  RetsServerError: rets.RetsServerError
  RetsReplyError: rets.RetsReplyError
}
