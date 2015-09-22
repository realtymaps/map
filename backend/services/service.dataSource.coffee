_ = require 'lodash'
Promise = require 'bluebird'
errorLib = require '../utils/util.partiallyHandledError'
# {PartiallyHandledError, isUnhandled} = require './util.partiallyHandledError'
tables = require '../config/tables'


rets = require 'rets-client'
encryptor = require '../config/encryptor'
moment = require('moment')
logger = require '../config/logger'
require '../config/promisify'
memoize = require 'memoizee'

getDataDump = (mlsInfo, limit, minDate=0) ->
  # _getRetsClient mlsInfo.url, mlsInfo.username, mlsInfo.password, mlsInfo.static_ip, (retsClient) ->
  #   if !mlsInfo.listing_data.queryTemplate || !mlsInfo.listing_data.field
  #     throw new PartiallyHandledError('Cannot query without a datetime format to filter (check MLS config fields "Update Timestamp Column" and "Formatting")')
  #   momentThreshold = moment.utc(new Date(minDate)).format(mlsInfo.listing_data.queryTemplate.replace("__FIELD_NAME__", mlsInfo.listing_data.field))
  #   retsClient.search.query(mlsInfo.listing_data.db, mlsInfo.listing_data.table, momentThreshold, limit: limit)
  #   .then (results) ->
  #     retsClient.metadata.getTable(mlsInfo.listing_data.db, mlsInfo.listing_data.table)
  #     .catch isUnhandled, (error) ->
  #       if error.replyCode
  #         error = new Error("#{error.replyText} (#{error.replyCode})")
  #       throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
  #     .then (response) ->
  #       fieldMappings = {}
  #       for field in response.Fields
  #         if field.LongName.indexOf('.') != -1
  #           fieldMappings[field.LongName] = field.LongName.replace(/\./g, '')
  #       if _.isEmpty(fieldMappings)
  #         return results
  #       for result in results
  #         for oldName, newName of fieldMappings
  #           if oldName of result
  #             result[newName] = result[oldName]
  #             delete result[oldName]
  #       return results
  # .catch isUnhandled, (error) ->
  #   if error.replyCode == "#{rets.replycode.NO_RECORDS_FOUND}"
  #     # code for 0 results, not really an error (DMQL is a clunky language)
  #     return []
  #   # TODO: else if error.replyCode == rets.replycode.MAX_RECORDS_EXCEEDED # "20208"
  #   if error.replyCode
  #     error = new Error("#{error.replyText} (#{error.replyCode})")
  #   # code for too many results, must manually paginate or something to get all the data
  #   throw new PartiallyHandledError(error, 'failed to query RETS system')

getColumnList = (dataSourceId, dataSourceType, dataListType) ->
  logger.debug "\n\n#### getColumnList()"
  logger.debug dataSourceId
  logger.debug dataSourceType
  logger.debug dataListType
  query = tables.config.dataSource()
  .select(
    'metadataentryid as MetadataEntryID',
    'systemname as SystemName',
    'shortname as ShortName',
    'longname as LongName',
    'datatype as DataType',
    'interpretation as Interpretation',
    'lookupname as LookupName'
  )
  .where
    data_source_id: dataSourceId
    data_source_type: dataSourceType
    data_list_type: dataListType
  .catch errorLib.isUnhandled, (error) ->
    throw new errorLib.PartiallyHandledError(error, "Failed to retrieve #{dataSourceId} columns")
  .then (response) ->
    logger.debug "\n\n#### response:"
    logger.debug JSON.stringify(response)
    # _.map response.Fields, (r) ->
    #   _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
    response
  .then (fields) ->
    logger.debug "\n\n#### fields:"
    for field in fields
      field.LongName = field.LongName.replace(/\./g, '')
    fields
  logger.sql query.toString()
  query
    

  # _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
  #   retsClient.metadata.getTable(databaseName, tableName)
  #   .catch isUnhandled, (error) ->
  #     if error.replyCode
  #       error = new Error("#{error.replyText} (#{error.replyCode})")
  #     throw new PartiallyHandledError(error, 'Failed to retrieve RETS columns')
  #   .then (response) ->
  #     _.map response.Fields, (r) ->
  #       _.pick r, ['MetadataEntryID', 'SystemName', 'ShortName', 'LongName', 'DataType', 'Interpretation', 'LookupName']
  #   .then (fields) ->
  #     for field in fields
  #       field.LongName = field.LongName.replace(/\./g, '')
  #     fields
        

getLookupTypes = (serverInfo, databaseName, lookupId) ->
  # _getRetsClient serverInfo.url, serverInfo.username, serverInfo.password, serverInfo.static_ip, (retsClient) ->
  #   retsClient.metadata.getLookupTypes(databaseName, lookupId)
  #   .catch isUnhandled, (error) ->
  #     if error.replyCode
  #       error = new Error("#{error.replyText} (#{error.replyCode})")
  #     throw new PartiallyHandledError(error, 'Failed to retrieve RETS types')
  #   .then (response) ->
  #     response.LookupTypes


module.exports =
  getColumnList: getColumnList
  getLookupTypes: getLookupTypes
  getDataDump: getDataDump
