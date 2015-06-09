Promise = require "bluebird"
logger = require '../config/logger'
_ = require 'lodash'
moment = require 'moment'
_createFtp = require '../utils/util.ftpPromisified'
{getRawTableName, getLastStartTime, createDataHistoryEntry} = require '../utils/tasks/util.taskHelpers'
dataSourceType = 'parcels'


DIGIMAPS =
    DIRECTORIES:[{name:"DELIVERIES"}, {name: "DMP_DELIVERY_", doParseDate:true}, {name:"ZIPS"}]
    FILE:{name:"Parcels_", appendFipsCode:true, ext:".zip"}

_getClientFromDigiSettings = (digiMapsSettings) ->
    logger.debug digiMapsSettings
    if _.isFunction digiMapsSettings?.then
        return digiMapsSettings
    {URL, ACCOUNT, PASSWORD} = digiMapsSettings
    _createFtp(URL, ACCOUNT, PASSWORD)


_numbersInString = (str) -> str.replace(/\D/g, '')

_fipsCodesFromListing = (ls) ->
    ls.map (l) -> _numbersInString(l)
###
To define an import in digimaps_parcel_imports we need to get folderNames and fipsCodes

- 1
    Get All new Imports (folderNamesToProcess) post last_start_time
- 2
    For each folderNamesToProcess create an entry to process each FILE
- 3 then insert each object into digimaps_parcel_imports
###
_defineImports = (subtask, digiMapsSettings, rootDir = DIGIMAPS.DIRECTORIES[0].name, endDir = DIGIMAPS.DIRECTORIES[2].name) -> Promise.try ->
    folderNamesToAdd = null
    importsToAdd = []
    rawTableName = getRawTableName(subtask)

    _getClientFromDigiSettings(digiMapsSettings)
    .then (client) -> #step 1
        client.cwdAsync './' + rootDir
        .then (dir) ->
            logger.debug 'defineImports: step 1'
            client.listAsync()
            .then (ls) ->
                logger.debug 'defineImports: step 1 listing folderNames'

                folderObjs = ls.map (l) ->
                    name: l.name
                    moment: moment(_numbersInString(l.name), 'YYYYMMDD').utc()

                getLastStartTime(subtask.task_name)
                .then (lastStartDate) ->
                    lastStartDate = moment(lastStartDate).utc()
                    folderObjs = _.filter folderObjs, (o) ->
                        unixTime = o.moment.unix() - lastStartDate.unix()
                        unixTime > 0

                    folderObjs.map (f) -> f.name
        .finally ->
            logger.debug "closing client"
            client.end()
        .then (folderNamesToProcess) -> #step 2
            logger.debug 'defineImports: step 2'
            promises = []

            _getImports = (lPath) ->
                _getClientFromDigiSettings(digiMapsSettings).then (getClient) ->
                    getClient.cwdAsync(lPath).then ->
                        getClient.pwdAsync().then (path) ->
                            logger.debug "pwd: #{path}"
                        getClient.listAsync()
                    .then (ls) ->
                        logger.debug "defineImports: step 2, file count: #{ls?.length}"
                        ls?.forEach (l) ->
                            importsToAdd.push
                                data_source_id: "#{lPath}/#{l.name}"
                                data_source_type: dataSourceType
                                batch_id: subtask.batch_id
                                raw_table_name: rawTableName
                    .finally ->
                        logger.debug "closing getClient"
                        getClient.end();

            for key, name of folderNamesToProcess
                fullPath = "/#{rootDir}/#{name}/#{endDir}"
                logger.debug "defineImports: step 2, fullPath: #{fullPath}"
                promises.push _getImports(fullPath)

            logger.debug "defineImports: step 2"
            Promise.all promises
        .then -> #step 3
            logger.debug 'defineImports: step 3'
            # logger.debug importsToAdd
            createDataHistoryEntry(importsToAdd)

_getFileName = (fipsCode) ->
    if DIGIMAPS.FILE?.appendFipsCode == true
        return DIGIMAPS.FILE.name + String(fipsCode) + DIGIMAPS.FILE.ext
    DIGIMAPS.FILE.name

_getParcelZipFileStream = (fipsCode, fullPath, digiMapsSettings) ->
    _getClientFromDigiSettings(digiMapsSettings)
    .then (client) ->
        fileName = _getFileName(fipsCode)
        logger.debug(fileName)
        client.cwdAsync(fullPath)
        .then ->
            client.pwdAsync()
        .then (dirName) ->
            new Promise (resolve, reject) ->
                client.listAsync()
                .then (ls) ->
                    hasFipsCode = _.contains _fipsCodesFromListing(ls), String(fipsCode)
                    if hasFipsCode
                        logger.debug("downloading: #{fileName} in #{dirName}")
                        return resolve(dirName)
                    return reject('FipsCode does not exist.')
                .catch reject
        .then ->
            client.getAsync(fileName)
        .then (stream) -> Promise.try ->
            logger.debug("download complete: #{fileName}")
            stream.on 'error', (err) ->
                logger.debug "stream error: #{err}"
                client.end()
                throw err
            stream.on 'close', ->
                logger.debug 'stream close'
                client.end()
            stream

module.exports =
    getParcelZipFileStream: _getParcelZipFileStream
    defineImports: _defineImports
