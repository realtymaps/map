_ = require 'lodash'
Promise = require 'bluebird'
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
rets = require 'rets-client'
logger = require('../config/logger').spawn('service:rets')
require '../config/promisify'
through2 = require 'through2'
externalAccounts = require './service.externalAccounts'
internals = require './service.rets.internals'


getDatabaseList = (serverInfo) ->
  externalAccounts.getAccountInfo(serverInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, serverInfo.static_ip, (retsClient) ->
      retsClient.metadata.getResources()
      .catch (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS databases')
      .then (response) ->
        _.map response.results[0].metadata, (r) ->
          _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']

getObjectList = (serverInfo) ->
  externalAccounts.getAccountInfo(serverInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, serverInfo.static_ip, (retsClient) ->
      retsClient.metadata.getObject('0')
      .catch (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS objects')
      .then (response) ->
        _.map response.results[0].metadata, (r) ->
          _.pick r, ['ResourceID', 'StandardName', 'VisibleName', 'ObjectVersion']


getTableList = (serverInfo, databaseName) ->
  externalAccounts.getAccountInfo(serverInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, serverInfo.static_ip, (retsClient) ->
      retsClient.metadata.getClass(databaseName)
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS tables')
      .then (response) ->
        _.map response.results[0].metadata, (r) ->
          _.pick r, ['ClassName', 'StandardName', 'VisibleName', 'TableVersion']

getColumnList = (serverInfo, databaseName, tableName) ->
  externalAccounts.getAccountInfo(serverInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, serverInfo.static_ip, (retsClient) ->
      retsClient.metadata.getTable(databaseName, tableName)
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS columns')
      .then (response) ->
        _.map response.results[0].metadata, (r) ->
          _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
      .then (fields) ->
        reverseMappings = {}
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
  externalAccounts.getAccountInfo(serverInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, serverInfo.static_ip, (retsClient) ->
      retsClient.metadata.getLookupTypes(databaseName, lookupId)
      .catch errorHandlingUtils.isUnhandled, (error) ->
        throw new errorHandlingUtils.PartiallyHandledError(error, 'Failed to retrieve RETS types')
      .then (response) ->
        response.results[0].metadata


getDataStream = (mlsInfo, opts={}) ->
  externalAccounts.getAccountInfo(mlsInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, mlsInfo.static_ip, (retsClient) ->
      if !mlsInfo.listing_data.field
        throw new errorHandlingUtils.PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config field "Update Timestamp Column")')
      getColumnList(mlsInfo, mlsInfo.listing_data.db, mlsInfo.listing_data.table)
      .then (columnData) ->
        fieldMappings = {}
        for field in columnData
          fieldMappings[field.SystemName] = field.LongName
        total = 0
        opts.searchOptions.limit = 100
        searchQuery = internals.buildSearchQuery(mlsInfo, opts)
        searchOptions =
          count: 0
        _.extend(searchOptions, opts.searchOptions)
        fullLimit = opts.searchOptions.limit
        if opts.subLimit
          searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)

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
            internals.getRetsClient creds.url, creds.username, creds.password, mlsInfo.static_ip, (retsClientIteration) ->
              new Promise (resolve2, reject2) ->
                retsStream = retsClientIteration.search.stream.query(mlsInfo.listing_data.db, mlsInfo.listing_data.table, searchQuery, searchOptions, true)
                retsStream.pipe(resultStream, end: false)
                retsStream.on 'end', resolve2
                resolved = true
                resolve(retsStream)
            .catch (error) ->
              if !resolved
                resolved = true
                reject(error)
        resultStream = through2.obj (event, encoding, callback) ->
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
              if event.payload.maxRowsExceeded && (!fullLimit || total < fullLimit)
                searchOptions.offset = total
                if fullLimit
                  searchOptions.limit = fullLimit - total
                  if opts.subLimit
                    searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)
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
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to query RETS system')


getDataChunks = (mlsInfo, handler, opts={}) ->
  externalAccounts.getAccountInfo(mlsInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, mlsInfo.static_ip, (retsClient) ->
      if !mlsInfo.listing_data.field
        throw new errorHandlingUtils.PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config field "Update Timestamp Column")')
      total = 0
      opts.searchOptions.limit = 90
      searchQuery = internals.buildSearchQuery(mlsInfo, opts)
      searchOptions =
        count: 0
      _.extend(searchOptions, opts.searchOptions)
      fullLimit = opts.searchOptions.limit
      if opts.subLimit
        searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)

      searchIteration = () ->
        internals.getRetsClient creds.url, creds.username, creds.password, mlsInfo.static_ip, (retsClientIteration) ->
          retsClientIteration.search.query(mlsInfo.listing_data.db, mlsInfo.listing_data.table, searchQuery, searchOptions)
          .then (response) ->
            total += response.results.length
            if response.maxRowsExceeded && (!fullLimit || total < fullLimit)
              searchOptions.offset = total
              if fullLimit
                searchOptions.limit = fullLimit - total
                if opts.subLimit
                  searchOptions.limit = Math.min(searchOptions.limit, opts.subLimit)
              handler(response.results)
              .catch errorHandlingUtils.isUnhandled, (err) ->
                throw new errorHandlingUtils.PartiallyHandledError(err, 'error in chunk handler')
              .then () ->
                searchIteration()
            else
              handler(response.results)
              .then () ->
                return total
          .catch rets.RetsReplyError, (err) ->
            if err.replyTag == "NO_RECORDS_FOUND" && total > 0
              # code for 0 results, not really an error (DMQL is a clunky language)
              return total
            else
              throw err

      searchIteration()

  .catch errorHandlingUtils.isUnhandled, (error) ->
    throw new errorHandlingUtils.PartiallyHandledError(error, 'failed to query RETS system')


getPhotosObject = ({serverInfo, databaseName, photoIds, objectsOpts, photoType}) ->
  objectsOpts ?= alwaysGroupObjects: true, ObjectData: '*'
  photoType ?= 'Photo'

  externalAccounts.getAccountInfo(serverInfo.id)
  .then (creds) ->
    internals.getRetsClient creds.url, creds.username, creds.password, serverInfo.static_ip, (retsClient) ->
      retsClient.objects.stream.getObjects(databaseName, photoType, photoIds, objectsOpts)


module.exports = {
  getDatabaseList
  getTableList
  getColumnList
  getLookupTypes
  getDataStream
  getDataChunks
  getPhotosObject
  getObjectList
  isTransientRetsError: internals.isTransientRetsError
  RetsError: rets.RetsError
  RetsServerError: rets.RetsServerError
  RetsReplyError: rets.RetsReplyError
}
