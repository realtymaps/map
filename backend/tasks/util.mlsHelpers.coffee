_ = require 'lodash'
Promise = require 'bluebird'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
dbs = require '../config/dbs'
logger = require('../config/logger').spawn('util.mlsHelpers')
finePhotologger = logger.spawn('photos.fine')
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
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
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
      retsHelpers.getDataStream(mlsInfo, options?.limit, refreshThreshold)
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
      deletes = if refreshThreshold.getTime() == 0 then dataLoadHelpers.DELETE.UNTOUCHED else dataLoadHelpers.DELETE.NONE
      {numRawRows, deletes}
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
      return tables.deletes.property()
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

_getPhotoSettings = (subtask, id) ->
  mlsConfigQuery = tables.config.mls().where(id: subtask.task_name).then sqlHelpers.expectSingleRow

  query = tables.property.combined()
  .where
    id: id
    data_source_type: 'mls'
    data_source_id: subtask.task_name

  Promise.all [mlsConfigQuery, query]

_updatePhotoUrl = (subtask, opts) -> Promise.try () ->
  if !opts
    logger.debug 'GTFO: _updatePhotoUrl'
    return

  onMissingArgsFail
    args: opts
    required: ['newFileName', 'imageId', 'photo_id']

  {newFileName, imageId, photo_id, uploadDate, description} = opts
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
    obj =
      url: "https://s3.amazonaws.com/#{s3Info.other.bucket}/#{newFileName}"

    obj.uploadDate = uploadDate if uploadDate
    obj.description = description if description

    jsonObjStr = JSON.stringify obj

    finePhotologger.debug jsonObjStr

    query =
      tables.property.combined()
      .raw("""
        UPDATE data_combined set
        photos=jsonb_set(photos, '{#{imageId}}', '#{jsonObjStr}', true)
        WHERE data_source_type = 'mls' AND
         data_source_id = '#{subtask.task_name}' AND
         photo_id = '#{photo_id}';
        """
      )

    finePhotologger.debug query.toString()
    query

_enqueuePhotoToDelete = (key, batch_id) ->
  if key?
    tables.deletes.photos()
    .insert {key, batch_id}
  else
    Promise.resolve()

###
  using upload see service.aws.putObject comments

  The short of it is that we do not know the size of the payload. EVEN if rets-client gives a size if it is invalid
  it causes too many problems. It is easier to forgoe worying about size and just upload blindly!
###
_uploadPhoto = ({photoRes, newFileName, payload, row}) ->
  new Promise (resolve, reject) ->
    awsService.upload
      extAcctName: EXT_AWS_PHOTO_ACCOUNT
      Key: newFileName
      ContentType: payload.contentType
      Metadata:
        id: row.id
        rm_property_id: row.rm_property_id
        height: photoRes.height
        width: photoRes.width
    .then (upload) ->

      upload.on 'uploaded', (details) ->
        logger.debug details
        resolve(details)

      upload.on 'error', (error) ->
        reject error

      payload.data.pipe(upload)

storePhotos = (subtask, id) ->
  finePhotologger.debug subtask.task_name

  _getPhotoSettings(subtask, id)
  .then ([mlsConfig, rows]) ->

    if !rows.length
      finePhotologger.debug 'No rows GTFO'
      return Promise.resolve()

    [row] = rows
    finePhotologger.debug "id: #{id}"

    #if the photo set is not updated GTFO
    logger.debug row.photo_last_mod_time

    if row.photo_last_mod_time? && row.photo_download_last_mod_time? &&
    row.photo_last_mod_time == row.photo_download_last_mod_time
      finePhotologger.debug 'photo_last_mod_time identical  GTFO'
      return Promise.resolve()

    {photo_id} = row
    photoIds = {}
    #get all photos for a specific property
    photoIds[photo_id] = '*'

    finePhotologger.debug photoIds

    photoType = mlsConfig.listing_data.largestPhotoObject
    {photoRes} = mlsConfig.listing_data

    retsHelpers.getPhotosObject {
      serverInfo: mlsConfig
      databaseName: 'Property'
      photoIds
      photoType
    }
    .then (obj) ->
      successCtr = 0
      errorsCtr = 0
      skipsCtr = 0
      promises = []

      savesPromise = new Promise (resolve, reject) ->
        mlsPhotoUtil.imagesHandle obj, (err, payload, isEnd) ->

          if(err)
            logger.debug 'ERROR: rets-client getObjects!!!!!!!!!!!!!'
            logger.error err
            return reject err

          if(isEnd)
            return resolve(
              Promise.all promises
              .then (args...) ->
                logger.debug "Uploaded #{successCtr} photos to aws bucket."
                logger.debug "Skipped #{skipsCtr} photos to aws bucket."
                logger.debug "Failed to upload #{errorsCtr} photos to aws bucket."
                args
            )

          #file naming consideratons
          #http://docs.aws.amazon.com/AmazonS3/latest/dev/request-rate-perf-considerations.html
          newFileName = "#{uuid.genUUID()}/#{subtask.task_name}/#{payload.name}"
          {imageId, uploadDate, description} = payload

          logger.debug _.omit payload, 'data'

          if mlsPhotoUtil.hasSameUploadDate(uploadDate, row.photos[imageId]?.uploadDate)
            skipsCtr++
            finePhotologger.debug 'photo has same updateDate GTFO.'
            return promises.push Promise.resolve(null)

          promises.push(
            _uploadPhoto({photoRes, newFileName, payload, row})
            .then () ->
              _enqueuePhotoToDelete row.photos[imageId], subtask.batch_id
            .then () ->
              logger.debug 'photo upload success'
              successCtr++

              tables.property.combined()
              .where(id: row.id)
              .update(photo_import_error: null)
              .then () ->
                {newFileName, imageId, photo_id, uploadDate, description}
            .catch (error) ->
              logger.debug 'ERROR: putObject!!!!!!!!!!!!!!!!'
              logger.debug error
              logger.debug error.stack
              #record the error an move on
              tables.property.combined()
              .where(id: row.id)
              .update(photo_import_error: error.stack)
              .then () ->
                null
          )

      savesPromise.then ([saves]) ->
        #filter/flatMap (remove nulls / GTFOS)
        Promise.all _.filter(saves).map _updatePhotoUrl.bind(null, subtask)

deleteOldPhoto = (subtask, id) -> Promise.try () ->
  tables.deletes.photo()
  .where {id}
  .then sqlHelpers.expectSingleRow #might not want to throw and just continue to try and delte the rest
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
