logger = require('../config/logger').spawn('routes:mls:internals')
validation = require '../utils/util.validation'
retsService = require '../services/service.rets'
_ = require 'lodash'
through = require 'through2'
mlsHelpers = require '../tasks/util.mlsHelpers'
transforms = require '../utils/transforms/transforms.mls'
mlsRouteUtil = require '../utils/util.route.mls'
Promise =  require 'bluebird'
JSONStream = require 'JSONStream'
require '../extensions/stream'
memoize = require 'memoizee'

_getPhotoIds = null
_getPhotoIdsCached = null

getPhotoIds = (req, res, next) ->
  l = logger.spawn('getPhotoIds')
  validation.validateAndTransformRequest(req, transforms.getPhotoIds)
  .then (validReq) ->
    {mlsId} = validReq.params
    {lastModTimeField, uuidField, photoIdField, subLimit, limit} = validReq.query

    subLimit ?= 1
    limit ?= 2

    l.debug -> {mlsId, uuidField, photoIdField, subLimit}

    dataOptions = {
      subLimit
      searchOptions: {Select: "#{uuidField},#{photoIdField}", offset: 1, limit}
      listing_data: {lastModTime: lastModTimeField}
    }

    if !_getPhotoIds?
      l.debug -> '@@@@@ NOT CACHED _getPhotoIds: undefined @@@@@'

      _getPhotoIds = (_mlsId, _dataOptions, _res, _rowFields) ->
        l.debug -> '@@@@@ NOT CACHED inside _getPhotoIds @@@@@'
        retStream = through.obj (chunks, enc, cb) ->
          for chunk in chunks #flatten
            @push(chunk)
          cb()

        allChunks = []

        handleChunk = (chunk) -> Promise.try () ->
          if !chunk?.length
            return
          l.debug () -> "Found #{chunk.length} updated rows in chunk"
          # l.debug -> chunk

          for row,i in chunk
            chunk[i] =
              data_source_uuid: row[_rowFields.uuidField]
              photo_id: row[_rowFields.photoIdField]

          # l.debug -> chunk
          allChunks.push(chunk)
          retStream.write(chunk)

        l.debug () -> "Getting data chunks for #{_mlsId}: #{JSON.stringify(_dataOptions)}"
        retsService.getDataChunks(_mlsId, 'listing', _dataOptions, handleChunk)
        .then () ->
          logger.debug -> "done: retsService.getDataChunks"
          retStream.end()
        .catch (err) ->
          retStream.error(err)

        # stream portion should only run the first time (not on cache hits)
        # since some MLSes are dog **** slow stream the response
        _res.type("application/json")
        _res.started = true

        retStream
        .pipe(JSONStream.stringify())
        .pipe(_res)
        .toPromise()
        .then () ->
          allChunks = _.flatten(allChunks)

      #TODO: eventually figure out a clean way to add cache supports to our routes
      # this seems way to hard to do something that should be trivial
      # keep in mind we need to consider the req.user (session), and req
      _getPhotoIdsCached = memoize.promise(_getPhotoIds,
        maxAge: 15*60*1000
        normalizer: (args) ->
          #args is arguments object as accessible in memoized function
          JSON.stringify(args[0]) + JSON.stringify(args[1])
        dispose: () ->
          _getPhotoIds = null
      )

    _getPhotoIdsCached(mlsId, dataOptions, res, {uuidField, photoIdField})
    .then (result) ->
      if !res.started
        l.debug -> '@@@@ CACHED result @@@@'
        res.json(result)


# example
#   https://localhost:8085/api/mls/swflmls/databases/Property/2329201
#
# Grabs image zero of 2329201
getParamPhoto = ({req, res, next, photoType}) ->
  validation.validateAndTransformRequest(req, transforms.paramPhoto)
  .then (validReq) ->
    photoType = validReq.query.photoType || photoType
    {objectsOpts} = validReq.query

    mlsRouteUtil.getPhoto({entity: validReq.params, res, next, photoType, objectsOpts})

# example
# single image:
#   https://localhost:8085/api/mls/swflmls/databases/Property/photos?ids={"2329201":0}
# archive/zip:
#   https://localhost:8085/api/mls/swflmls/databases/Property/photos?ids={"2329201":*}
getQueryPhoto = ({req, res, next, photoType}) ->
  logger.debug -> "req.query"
  logger.debug -> req.query

  validation.validateAndTransformRequest(req, transforms.queryPhoto)
  .then (validReq) ->
    logger.debug -> "validReq.query"
    logger.debug -> validReq.query

    photoType = validReq.query.photoType || photoType
    {objectsOpts} = validReq.query
    mlsRouteUtil.getPhoto({entity: _.merge(validReq.params, photoIds:validReq.query.ids), res, next, photoType, objectsOpts})

# this  gets some data from a RETS server based on a query, and returns it as an array of row objects plus and array of
# column names as suitable for passing directly to a csv library we use.  The intent here is to allow us to get a
# sample of e.g. 1000 rows of data to look at when figuring out how to configure a new MLS
getDataDump = (mlsId, dataType, query) ->
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


TEST_SIZE = 20
BASE_OFFSET = 5
OVERLAP_SIZE = 10
testOverlapSettings = (mlsId) ->
  results = null
  resultsMap = null
  results2 = null
  mlsHelpers.getMlsField(mlsId, 'data_source_uuid', 'listing')
  .then (uuidField) ->
    processFirstResults = (data) ->
      results = data
      resultsMap = _.indexBy(data, uuidField)
    retsService.getDataChunks(mlsId, 'listing', searchOptions: {limit: TEST_SIZE, offset: BASE_OFFSET}, processFirstResults)
    .then () ->
      if results?.length != TEST_SIZE
        return {error: "got #{results?.length} initial results, expected #{TEST_SIZE}"}
      if Object.keys(resultsMap).length != TEST_SIZE
        return {error: "got #{Object.keys(resultsMap).length} unique IDs, expected #{TEST_SIZE}; is MLS Listing ID configured properly?"}
      processSecondResults = (data2) ->
        results2 = data2
      retsService.getDataChunks(mlsId, 'listing', searchOptions: {limit: TEST_SIZE, offset: BASE_OFFSET+TEST_SIZE-OVERLAP_SIZE}, processSecondResults)
      .then () ->
        if results2?.length != TEST_SIZE
          return {error: "got #{results2?.length} secondary results, expected #{TEST_SIZE}"}
        overlapCount = 0
        for row in results2
          if resultsMap[row[uuidField]]
            overlapCount++
        inOrder = true
        for i in [0...overlapCount]
          if results2[i][uuidField] != results[i+TEST_SIZE-overlapCount][uuidField]
            inOrder = false
            break
        return {
          expected: OVERLAP_SIZE
          actual: overlapCount
          inOrder
        }


module.exports = {
  getPhotoIds
  getQueryPhoto
  getParamPhoto
  getDataDump
  testOverlapSettings
}
