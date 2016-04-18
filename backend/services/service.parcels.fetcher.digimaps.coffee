Promise = require 'bluebird'
_ = require 'lodash'
shp2json = require 'shp2jsonx'
through = require 'through'
JSONStream = require 'JSONStream'
PromiseFtp = require 'promise-ftp'
parcelUtils = require '../utils/util.parcel'

logger = require('../config/logger').spawn('digimaps:parcelFetcher')
clientClose = require '../utils/util.client.close'
{onMissingArgsFail} = require '../utils/errors/util.errors.args'

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
      throw new Error "No Parcel Server Response"
    ftp

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
        _.filter paths, (p) ->
          !p.match(/archived/i)
    .finally ->
      logger.debug 'closing client'
      client.end()
    .then (folderNamesToProcess) -> #step 2
      logger.debug 'defineImports: step 2'
      promises = []

      _getImports = (lPath) ->
        #unique client for each pwd / ls combo as multiple Promises will occur at once
        #otherwise a single client will race itself and cause wierd errors
        _ftpClientFactory(creds).then (getClient) ->
          Promise.try () ->
            # logger.debug "lPath!!!!!!!!!!!!!!!"
            # logger.debug lPath
            getClient.cwd(lPath).then ->
              getClient.pwd().then (path) ->
                logger.debug "pwd: #{path}"
              getClient.list()
          .then (ls) ->
            logger.debug "defineImports: step 2, file count: #{ls?.length}"
            if ls?
              importsToAdd.push "#{lPath}/#{l.name}" for l in ls

          .finally ->
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
  logger.debug "Attempting to download parcel zip: #{fullPath}"

  _ftpClientFactory(creds)
  .then (client) ->
    client.get(fullPath)
    .then (stream) ->
      if doClose
        return clientClose.onEndStream {stream, client, where: 'getZipFileStream'}
      {client, stream}

getParcelJsonStream = (fullPath, {creds} = {}) ->
  getZipFileStream(fullPath, {creds, doClose: false})
  .then ({client, stream}) ->
    clientClose.onEndStream {
      client
      stream: shp2json(stream).pipe(JSONStream.parse('*.features.*'))
      where: 'getParcelJsonStream'
    }

getFormatedParcelJsonStream = (fullPath, {creds} = {}) ->
  getParcelJsonStream(fullPath, {creds})
  .then (stream) ->
    write = (obj) ->
      @queue parcelUtils.formatParcel(obj)
    end = ->
      @queue null
    stream.pipe through(write, end)

module.exports = {
  getZipFileStream
  getParcelJsonStream
  getFormatedParcelJsonStream
  defineImports
}
