logger = require('../config/logger').spawn('routes:mls:internals')
ExpressResponse =  require '../utils/util.expressResponse'
validation = require '../utils/util.validation'
retsService = require '../services/service.rets'
mlsConfigService = require '../services/service.mls_config'
_ = require 'lodash'
photoUtil = require '../utils/util.mls.photos'
through = require 'through2'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
httpStatus = require '../../common/utils/httpStatus'


_hasNoStar = (photoIds) ->
  JSON.stringify(photoIds).indexOf('*') == -1

_isSingleImage = (photoIds) ->
  if _.isString(photoIds)
    return true
  if _.keys(photoIds).length == 1 and _hasNoStar(photoIds)
    return true
  false


_handleGenericImage = ({setContentTypeFn, getStreamFn, next, res}) ->
  setContentTypeFn()
  getStreamFn()
  .on 'error', (error) ->
    if isUnhandled(error)
      error = new PartiallyHandledError(error, 'uncaught image streaming error (*** add better error handling code to cover this case! ***)')
    next new ExpressResponse(error.message, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: error.quiet})
  .pipe(res)


_handleImage = ({res, next, object}) ->
  _handleGenericImage {
    res
    next
    setContentTypeFn: () ->
      res.type object.headerInfo.contentType
    getStreamFn: () ->
      photoUtil.imageStream(object)
  }


_handleImages = ({res, next, object, mlsId, photoIds}) ->
  _handleGenericImage {
    res
    next
    setContentTypeFn: () ->
      listingIds = _.keys(photoIds).join('_')
      res.attachment("#{mlsId}_#{listingIds}_photos.zip")
    getStreamFn: () ->
      photoUtil.imagesStream(object)
  }


_handleRetsObjectResponse = (res, next, photoIds, mlsId, object) ->
  opts = {res, next, photoIds, mlsId, object}

  logger.debug opts.object.headerInfo, true

  if _isSingleImage(opts.photoIds)
    return _handleImage(opts)
  _handleImages(opts)


_getPhoto = ({entity, res, next, photoType}) ->
  logger.debug entity

  {photoIds, mlsId, databaseId} = entity

  if photoIds == 'null' or photoIds  == 'empty'
    photoIds = null

  retsService.getPhotosObject({
    mlsId
    databaseName:databaseId
    photoIds
    photoType
  })
  .then (object) ->
    _handleRetsObjectResponse(res, next, photoIds, mlsId, object)
  .catch (error) ->
    if isUnhandled(error)
      error = new PartiallyHandledError(error, 'uncaught photo error (*** add better error handling code to cover this case! ***)')
    next new ExpressResponse(error.message||error, {status: httpStatus.INTERNAL_SERVER_ERROR, quiet: error.quiet})


getParamPhoto = ({req, res, next, photoType}) ->
  validation.validateAndTransformRequest req,
    params: validation.validators.object subValidateSeparate:
      photoIds: validation.validators.string(minLength:2)
      mlsId: validation.validators.string(minLength:2)
      databaseId: validation.validators.string(minLength:2)
    query: validation.validators.object subValidateSeparate:
      photoType: validation.validators.string(minLength:2)
    body: validation.validators.object isEmptyProtect: true
  .then (validReq) ->
    photoType = validReq.query.photoType || photoType

    _getPhoto({entity: validReq.params, res, next, photoType})


getQueryPhoto = ({req, res, next, photoType}) ->
  logger.debug "req.query"
  logger.debug req.query

  validation.validateAndTransformRequest req,
    params: validation.validators.object subValidateSeparate:
      mlsId: validation.validators.string(minLength:2)
      databaseId: validation.validators.string(minLength:2)
    query: validation.validators.object subValidateSeparate:
      ids: validation.validators.object(json:true)
      photoType: validation.validators.string(minLength:2)
    body: validation.validators.object isEmptyProtect: true
  .then (validReq) ->
    logger.debug "validReq.query"
    logger.debug validReq.query

    photoType = validReq.query.photoType || photoType
    _getPhoto({entity: _.merge(validReq.params, photoIds:validReq.query.ids), res, next, photoType})


# this  gets some data from a RETS server based on a query, and returns it as an array of row objects plus and array of
# column names as suitable for passing directly to a csv library we use.  The intent here is to allow us to get a
# sample of e.g. 1000 rows of data to look at when figuring out how to configure a new MLS
getDataDump = (mlsId, dataType, query, next) ->
  validations =
    limit: [validation.validators.integer(min: 1), validation.validators.defaults(defaultValue: 1000)]
  validation.validateAndTransformRequest(query, validations)
  .then (result) ->
    retsService.getDataStream(mlsId, dataType, searchOptions: {limit: result.limit})
  .then (retsStream) ->
    columns = null
    # consider just streaming the file as building up data takes up a considerable amount of memory
    data = []
    new Promise (resolve, reject) ->
      delimiter = null
      csvStreamer = through.obj (event, encoding, callback) ->
        switch event.type
          when 'data'
            data.push(event.payload[0..-1].split(delimiter))
          when 'delimiter'
            delimiter = event.payload
          when 'columns'
            columns = event.payload
          when 'done'
            resolve(data)
            retsStream.unpipe(csvStreamer)
            csvStreamer.end()
          when 'error'
            reject(event.payload)
            retsStream.unpipe(csvStreamer)
            csvStreamer.end()
        callback()
      retsStream.pipe(csvStreamer)
    .then () ->
      data: data
      options:
        columns: columns
        header: true



module.exports = {
  getQueryPhoto
  getParamPhoto
  getDataDump
}
