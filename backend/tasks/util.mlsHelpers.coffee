_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
dbs = require '../config/dbs'
logger = require('../config/logger')
jobQueue = require '../utils/util.jobQueue'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
retsHelpers = require '../utils/util.retsHelpers'
dataLoadHelpers = require './util.dataLoadHelpers'
rets = require 'rets-client'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
awsService = require '../services/service.aws'
mlsPhotoUtil = require '../utils/util.mls.photos'
uuid = require '../utils/util.uuid'
externalAccounts = require '../services/service.externalAccounts'
EXT_AWS_PHOTO_ACCOUNT = 'aws-listing-photos'

ONE_DAY_MILLISEC = 24*60*60*1000

# loads all records from a given (conceptual) table that have changed since the last successful run of the task
loadUpdates = (subtask, options) ->
  # figure out when we last got updates from this table
  jobQueue.getLastTaskStartTime(subtask.task_name)
  .then (lastSuccess) ->
    now = new Date()
    if now.getTime() - lastSuccess.getTime() > ONE_DAY_MILLISEC || now.getDate() != lastSuccess.getDate()
      # if more than a day has elapsed or we've crossed a calendar date boundary, refresh everything and handle deletes
      logger.spawn('task:mls:'+subtask.task_name).debug("Last successful run: #{lastSuccess} === performing full refresh for #{subtask.task_name}")
      return new Date(0)
    else
      logger.spawn('task:mls:'+subtask.task_name).debug("Last successful run: #{lastSuccess} --- performing incremental update for #{subtask.task_name}")
      return lastSuccess
  .then (refreshThreshold) ->
    tables.config.mls()
    .where(id: subtask.task_name)
    .then (mlsInfo) ->
      mlsInfo = mlsInfo?[0]
      retsHelpers.getDataStream(mlsInfo, null, refreshThreshold)
      .catch isCausedBy(rets.RetsReplyError), (error) ->
        if error.replyTag in ["MISC_LOGIN_ERROR", "DUPLICATE_LOGIN_PROHIBITED", "SERVER_TEMPORARILY_DISABLED"]
          throw SoftFail(error, "Transient RETS error; try again later")
        throw error
    .then (retsStream) ->
      rawTableName = tables.temp.buildTableName(dataLoadHelpers.buildUniqueSubtaskName(subtask))
      dataLoadHistory =
        data_source_id: options.dataSourceId
        data_source_type: 'mls'
        data_type: 'listing'
        batch_id: subtask.batch_id
        raw_table_name: rawTableName
      dataLoadHelpers.manageRawDataStream(rawTableName, dataLoadHistory, retsStream)
      .catch isUnhandled, (error) ->
        throw new PartiallyHandledError(error, "failed to stream raw data to temp table: #{rawTableName}")
    .then (numRawRows) ->
      # now that we know we have data, queue up the rest of the subtasks (some have a flag depending
      # on whether this is a dump or an update)
      deletes = if refreshThreshold.getTime() == 0 then dataLoadHelpers.DELETE.UNTOUCHED else dataLoadHelpers.DELETE.NONE
      recordCountsPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_recordChangeCounts", {deletes: deletes, dataType: 'listing'}, true)
      finalizePrepPromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_finalizeDataPrep", null, true)
      activatePromise = jobQueue.queueSubsequentSubtask(null, subtask, "#{subtask.task_name}_activateNewData", {deletes: deletes}, true)
      Promise.join recordCountsPromise, finalizePrepPromise, activatePromise, () ->
        numRawRows
  .catch isUnhandled, (error) ->
    throw new PartiallyHandledError(error, 'failed to load RETS data for update')


buildRecord = (stats, usedKeys, rawData, dataType, normalizedData) -> Promise.try () ->
  # build the row's new values
  base = dataLoadHelpers.getValues(normalizedData.base || [])
  normalizedData.general.unshift(name: 'Address', value: base.address)
  normalizedData.general.unshift(name: 'Status', value: base.status_display)
  ungrouped = _.omit(rawData, usedKeys)
  if _.isEmpty(ungrouped)
    ungrouped = null
  data =
    address: sqlHelpers.safeJsonArray(base.address)
    hide_listing: base.hide_listing ? false
    shared_groups:
      general: normalizedData.general || []
      details: normalizedData.details || []
      listing: normalizedData.listing || []
      building: normalizedData.building || []
      dimensions: normalizedData.dimensions || []
      lot: normalizedData.lot || []
      location: normalizedData.location || []
      restrictions: normalizedData.restrictions || []
    subscriber_groups:
      contacts: normalizedData.contacts || []
      realtor: normalizedData.realtor || []
      sale: normalizedData.sale || []
    hidden_fields: dataLoadHelpers.getValues(normalizedData.hidden || [])
    ungrouped_fields: ungrouped
    deleted: null
  _.extend base, stats, data


finalizeData = (subtask, id) ->
  listingsPromise = tables.property.listing()
  .select('*')
  .where(rm_property_id: id)
  .whereNull('deleted')
  .where(hide_listing: false)
  .orderBy('rm_property_id')
  .orderBy('deleted')
  .orderBy('hide_listing')
  .orderByRaw('close_date DESC NULLS FIRST')
  parcelsPromise = tables.property.parcel()
  .select('geom_polys_raw AS geometry_raw', 'geom_polys_json AS geometry', 'geom_point_json AS geometry_center')
  .where(rm_property_id: id)
  Promise.join listingsPromise, parcelsPromise, (listings=[], parcel=[]) ->
    if listings.length == 0
      # might happen if a singleton listing is deleted during the day
      return tables.property.deletes()
      .insert
        rm_property_id: id
        data_source_id: subtask.task_name
        batch_id: subtask.batch_id

    # owner name promotion logic
    if !listings[0].owner_name? && !listings[0].owner_name_2?
      if listings[1]?.owner_name? || listings[1]?.owner_name_2?
        # keep the previously-promoted values
        promotionPromise = Promise.resolve(owner_name: listings[1].owner_name, owner_name_2: listings[1].owner_name_2)
      else
        # need to query the tax table to get values to promote
        promotionPromise = tables.property.combined()
        .select('owner_name', 'owner_name_2')
        .where
          rm_property_id: id
          data_source_type: 'county'
        .then (results=[]) ->
          results[0]
    else
      promotionPromise = Promise.resolve()

    promotionPromise
    .then (promotion) ->
      listing = dataLoadHelpers.finalizeEntry(listings)
      listing.data_source_type = 'mls'
      _.extend(listing, parcel[0], promotion)
      dbs.get('main').transaction (transaction) ->
        tables.property.combined(transaction: transaction)
        .where
          rm_property_id: id
          data_source_id: subtask.task_name
          active: false
        .delete()
        .then () ->
          tables.property.combined(transaction: transaction)
          .insert(listing)

_getPhotoSettings = (subtask, rm_property_id) ->
  photoTypePromise = tables.config.mls().where id: subtask.task_name
  .then sqlHelpers.expectSingleRow
  .then (mlsConfig) ->
    photoType = mlsConfig.listing_data.largestPhotoObject || 'Photo'
    logger.debug  "#{mlsConfig.id} photoType: #{photoType}"
    {photoType, photoRes:mlsConfig.photoRes}

  query = tables.property.combined()
  .where
    rm_property_id: rm_property_id
    data_source_type: 'mls'
    data_source_id: subtask.task_name

  logger.debug query.toString()

  Promise.all [photoTypePromise, query]

_updatePhotoUrl = (subtask, {newFileName, imageId, photo_id}) -> Promise.try () ->
  externalAccounts.getAccountInfo(EXT_AWS_PHOTO_ACCOUNT)
  .then (s3Info) ->
    ###
    Update photo's hash in a data_combined col
    example:
      photos:
        1: https://s3.amazonaws.com/uuid/swflmls/mls_id_1.jpeg
        2: https://s3.amazonaws.com/uuid/swflmls/mls_id_2.jpeg
        3: https://s3.amazonaws.com/uuid/swflmls/mls_id_1.jpeg
    ###
    url = "https://s3.amazonaws.com/#{s3Info.other.bucket}/#{newFileName}"

    query = tables.property.combined()
    .raw("""
      UPDATE config_mls set
      photos=jsonb_set(photos, '{#{imageId}}', '"#{url}"', true)"""
    )
    .where
      data_source_type: 'mls'
      data_source_id: subtask.task_name
      photo_id: photo_id

    logger.debug query.toString()
    query

_enqueuePhotoToDelete = (key, batch_id) ->
  if key?
    tables.deletes.photos()
    .insert {key, batch_id}
  else
    Promise.resolve()

storePhotos = (subtask, rm_property_id) ->
  logger.debug subtask.task_name

  _getPhotoSettings(subtask, rm_property_id)
  .then ([{photoType, photoRes}, rows]) ->
    Promise.all rows.map (row) ->
      {photo_id} = row
      photoIds = {}
      #get all photos for a specific property
      photoIds[photo_id] = '*'

      retsHelpers.getPhotosObject {
        serverInfo: subtask.task_name
        databaseName: 'Property'
        photoIds
        photoType
      }
      .then (obj) ->
        new Promise (resolve, reject) ->
          mlsPhotoUtil.imagesHandle obj, (err, payload, isEnd) ->
            if(err)
              reject err

            if(isEnd)
              resolve()

            newFileName = "#{uuid.genUUID()}/#{subtask.task_name}/#{payload.name}"
            {imageId} = payload
            #file naming consideratons
            #http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
            awsService.putObject
              extAcctName: EXT_AWS_PHOTO_ACCOUNT
              Key: newFileName
              Body: payload.data
              Metadata:
                rm_property_id: row.rm_property_id
                height: photoRes.height
                width: photoRes.width
            .then () ->
              _enqueuePhotoToDelete row.photos[imageId], subtask.batch_id
            .then () ->
              {newFileName, imageId, photo_id}
        .then _updatePhotoUrl.bind(null, subtask)

deleteOldPhoto = (subtask, id) -> Promise.try () ->
  tables.deletes.photo()
  .where {id}
  .then sqlHelpers.expectSingleRow
  .then ({id, key}) ->
    logger.debug "deleting: id: #{id}, key: #{key}"

    awsService.deleteObject
      extAcctName: EXT_AWS_PHOTO_ACCOUNT
      Key: key
    .then () ->
      tables.deletes.photo()
      .where {id}
      .del()
      .catch (error) ->
        throw SoftFail(error, "Transient Photo Deletion error; try again later. Failed to delete from database.")
    .catch (error) ->
      throw SoftFail(error, "Transient AWS Photo Deletion error; try again later")


module.exports = {
  loadUpdates
  buildRecord
  finalizeData
  storePhotos
  deleteOldPhoto
}
