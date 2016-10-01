Promise = require 'bluebird'
_ = require 'lodash'
shp2json = require 'shp2jsonx'
through2 = require 'through2'
JSONStream = require 'JSONStream'
PromiseFtp = require 'promise-ftp'
fs = require 'fs'

logger = require('../config/logger').spawn('digimaps:parcelFetcher')
finalStreamLogger = logger.spawn('finalStream')
chunkLogger = logger.spawn('chunk')
clientClose = require '../utils/util.client.close'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'
jobQueueErrors = require '../utils/errors/util.error.jobQueue'
tables =  require '../config/tables'

DIGIMAPS =
  DIRECTORIES:[{name:'DELIVERIES'}, {name: 'DMP_DELIVERY_', doParseDate:true}, {name:'ZIPS'}]
  FILE:{name:'Parcels_', appendFipsCode:true, ext:'.zip'}


_ftpClientFactory = (creds) -> Promise.try () ->
  # logger.debug digiMapsSettings
  if _.isFunction creds?.then
    return creds
  ftp = new PromiseFtp()
  ftp.connect
    host: creds.url
    user: creds.username
    password: creds.password
    autoReconnect: true
  .then (serverMsg) ->
    if !serverMsg?
      throw new Error "No parcel server response"
    ftp
  .catch (err) ->
    throw new jobQueueErrors.SoftFail(err, 'Error connecting to FTP server')

###
To define an import in digimaps_parcel_imports we need to get folderNames and fipsCodes
- 1 Get All new Imports (folderNamesToProcess) post last_start_time
- 2 For each folderNamesToProcess create an entry to process each FILE
- 3 then insert each object into data_load_history
###
defineImports = (opts) -> Promise.try ->
  {creds, rootDir, endDir} = onMissingArgsFail
    args: opts
    required: 'creds'

  rootDir ?= DIGIMAPS.DIRECTORIES[0].name
  endDir ?= DIGIMAPS.DIRECTORIES[2].name

  importsToAdd = []

  _ftpClientFactory(creds)
  .then (client) -> #step 1
    Promise.try () ->
      client.cwd './' + rootDir
    .then (dir) ->
      logger.debug 'defineImports: step 1'
      client.list()
      .then (ls) ->
        logger.debug 'defineImports: step 1 listing folderNames'

        paths = ls.map (l) -> l.name
        #ignore ARCHIVED since it has no dumps (ONLY xls)
        _.reject paths, (p) -> p.match(/archived/i)
    .finally ->
      logger.debug 'closing client'
      client.end()
    .then (folderNamesToProcess) -> #step 2
      logger.debug 'defineImports: step 2'
      promises = []

      _getImports = (lPath) ->
        #unique client for each pwd / ls combo as multiple Promises will occur at once
        #otherwise a single client will race itself and cause weird errors
        _ftpClientFactory(creds)
        .then (getClient) ->
          Promise.try () ->
            logger.debug "pwd: #{lPath}"
            getClient.cwd(lPath)
          .then () ->
            getClient.list()
          .then (ls) ->
            logger.debug "defineImports: step 2, file count: #{ls?.length}"
            if ls?
              importsToAdd.push "#{lPath}/#{l.name}" for l in ls
          .finally () ->
            logger.debug 'closing getClient'
            getClient.end()

      for key, name of folderNamesToProcess
        fullPath = "/#{rootDir}/#{name}/#{endDir}"
        logger.debug "defineImports: step 2, fullPath: #{fullPath}"
        promises.push _getImports(fullPath)

      logger.debug 'defineImports: step 2'
      Promise.all promises
    .then -> #step 3
      logger.debug 'defineImports: step 3'
      # logger.debug importsToAdd
      importsToAdd

getZipFileStream = (fullPath, {creds, doClose} = {}) ->
  doClose ?= true

  if !creds?
    logger.debug -> 'No credentials, trying local file system.'
    return Promise.resolve stream: fs.createReadStream(fullPath)

  logger.debug "Attempting to download parcel zip: #{fullPath}"

  _ftpClientFactory(creds)
  .then (client) ->
    client.get(fullPath)
    .then (stream) ->
      if doClose
        return clientClose.onEndStream {stream, client, where: 'getZipFileStream'}
      {client, stream}


getParcelJsonStream = ({fullPath, creds, streamPromise} = {}) ->
  streamPromise ?= getZipFileStream(fullPath, {creds, doClose: false})

  streamPromise
  .then ({client, stream}) -> new Promise (resolve, reject) ->
    ###
      DO NOT put `Promise.try () ->` here or it will hurt your world.
      Also do not put `Promise.try () ->` after using this function either.

      For some reason it will cause an error and blow up node in mid stream and in mid Promise.
    ###
    finalStreamLogger.debug -> 'stream resolved'

    ###
      Error handling / intercepting hell:
        In a nutshell we need to intercept the begining of a stream to make sure that we have valid
        data to move on to other streams via pipes.

      Breaking up into two explicit streams. So that intercept will not push data onto jsonStream and blow up
      with invalid data / errors.

      We use through2 (when it first has data) to resolve the jsonStream if we actually have something valid.
      Otherwise we reject.
    ###
    # we can't skipRegExes: [/Points/i] as that data has the street address and more info
    interceptStream = shp2json(stream, alwaysReturnArray: true)
    jsonStream = JSONStream.parse('*.features.*')

    firstTime = true
    t2Transform = (chunk, enc, cb) ->
      chunkLogger.debug -> 'chunk'
      chunkLogger.debug -> String(chunk)

      if firstTime
        firstTime = false
        resolve(jsonStream)
      @push chunk
      cb()

    t2Stream = through2 t2Transform, (cb) ->
      client?.end()
      cb()

    interceptStream.once 'error', (error) ->
      # logger.debug "interceptStream @@@@@@@@@@@@@@@@@@@ error"
      # logger.debug "NoShapeFilesError is instance: " + (error instanceof NoShapeFilesError)
      client?.end()
      if firstTime
        reject error
      else
        finalStreamLogger.error 'Your in limbo. The stream has errored and we are not handling it correctly.'
        finalStreamLogger.error error

    interceptStream.pipe(t2Stream).pipe(jsonStream)

rawParcelQuery = ({batch_id, fips_code, entity, select}) ->
  q = tables.temp(subid: "#{batch_id}_digimaps_parcel_#{fips_code}")

  q.select select if select?

  q.where(entity)

getRawParcelJsonStream = ({batch_id, fips_code, entity, select}) ->
  q = rawParcelQuery({batch_id, fips_code, entity, select})

  logger.debug -> q.toString()

  q.stream()
  .pipe through2.obj (chunk, encoding, cb) ->
    logger.debug -> "chunk type is string: #{_.isString chunk}"
    logger.debug -> chunk.feature
    this.push JSON.parse chunk.feature
    cb()


module.exports = {
  getZipFileStream
  getParcelJsonStream
  defineImports
  rawParcelQuery
  getRawParcelJsonStream
}
