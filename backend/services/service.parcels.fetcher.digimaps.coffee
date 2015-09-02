Promise = require 'bluebird'
logger = require '../config/logger'
_ = require 'lodash'
moment = require 'moment'
PromiseFtp = require '../utils/util.promiseFtp'
jobQueue = require '../utils/util.jobQueue'
tables = require '../config/tables'


DIGIMAPS =
  DIRECTORIES:[{name:'DELIVERIES'}, {name: 'DMP_DELIVERY_', doParseDate:true}, {name:'ZIPS'}]
  FILE:{name:'Parcels_', appendFipsCode:true, ext:'.zip'}

DATA_SOURCE_TYPE = 'parcels'

_getClientFromDigiSettings = (digiMapsSettings) ->
  # logger.debug digiMapsSettings
  if _.isFunction digiMapsSettings?.then
    return digiMapsSettings
  {URL, ACCOUNT, PASSWORD} = digiMapsSettings
  ftp = new PromiseFtp()
  ftp.connect
    host: URL
    user: ACCOUNT
    password: PASSWORD


_numbersInString = (str) -> str.replace(/\D/g, '')

_fipsCodesFromListing = (ls) ->
  ls.map (l) -> _numbersInString(l.name)
###
To define an import in digimaps_parcel_imports we need to get folderNames and fipsCodes

- 1 Get All new Imports (folderNamesToProcess) post last_start_time

- 2 For each folderNamesToProcess create an entry to process each FILE

- 3 then insert each object into data_load_history
###
_defineImports = (subtask, digiMapsSettings, rootDir = DIGIMAPS.DIRECTORIES[0].name, endDir = DIGIMAPS.DIRECTORIES[2].name) -> Promise.try ->
  folderNamesToAdd = null
  importsToAdd = []

  _getClientFromDigiSettings(digiMapsSettings)
  .then (client) -> #step 1
    client.cwd './' + rootDir
    .then (dir) ->
      logger.debug 'defineImports: step 1'
      client.list()
      .then (ls) ->
        logger.debug 'defineImports: step 1 listing folderNames'

        folderObjs = ls.map (l) ->
          name: l.name
          moment: moment(_numbersInString(l.name), 'YYYYMMDD').utc()

        jobQueue.getLastTaskStartTime(subtask.task_name)
        .then (lastStartDate) ->
          lastStartDate = moment(lastStartDate).utc()
          folderObjs = _.filter folderObjs, (o) ->
            unixTime = o.moment.unix() - lastStartDate.unix()
            unixTime > 0

          folderObjs.map (f) -> f.name
    .finally ->
      logger.debug 'closing client'
      client.end()
    .then (folderNamesToProcess) -> #step 2
      logger.debug 'defineImports: step 2'
      promises = []

      _getImports = (lPath) ->
        #unique client for each pwd / ls combo as multiple Promises will occur at once
        #otherwise a single client will race itself and cause wierd errors
        _getClientFromDigiSettings(digiMapsSettings).then (getClient) ->
          getClient.cwd(lPath).then ->
            getClient.pwd().then (path) ->
              logger.debug "pwd: #{path}"
            getClient.list()
          .then (ls) ->
            logger.debug "defineImports: step 2, file count: #{ls?.length}"
            ls?.forEach (l) ->
              importsToAdd.push
                data_source_id: "#{lPath}/#{l.name}"
                data_source_type: DATA_SOURCE_TYPE
                batch_id: subtask.batch_id

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
      tables.jobQueue.dataLoadHistory()
      .insert(importsToAdd)
      importsToAdd

_getParcelZipFileStream = (fullPath, digiMapsSettings) -> Promise.try ->
  _getClientFromDigiSettings(digiMapsSettings).then (client) ->
    client.get(fullPath)
    .then (stream) -> Promise.try ->
      logger.debug("download complete: #{fullPath}")
      stream.on 'error', (err) ->
        logger.error "stream error: #{err}"
        client.end()
        throw err
      stream.on 'close', ->
        logger.debug 'stream close'
        client.end()
      stream

module.exports =
  getParcelZipFileStream: _getParcelZipFileStream
  defineImports: _defineImports
