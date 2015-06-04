Promise = require "bluebird"
logger = require '../config/logger'
_ = require 'lodash'
_createFtp = require '../utils/util.ftpPromisified'

_digiMapsImports =  require './service.digimaps.parcel.imports'

DIGIMAPS =
    DIRECTORIES:[{name:"DELIVERIES"}, {name: "DMP_DELIVERY_", doParseDate:true}, {name:"ZIPS"}]
    FILE:{name:"Parcels_", appendFipsCode:true, ext:".zip"}

_getClientFromDigiSettings = (digiMapsSettings) ->
    logger.debug digiMapsSettings
    if _.isFunction digiMapsSettings?.then
        return digiMapsSettings
    {URL, ACCOUNT, PASSWORD} = digiMapsSettings
    _createFtp(URL, ACCOUNT, PASSWORD)


_fipsCodesFromListing = (ls) ->
    ls.map (l) -> l.name.replace(/\D/g, '')
###
To define an import in digimaps_parcel_imports we need to get folderNames and fipsCodes

- 1 First we need to get alll directories that are not imported_time
  - listAsync all DELIVERY_ ..folderNames
  - then get all imported fodlerNames to remove drom the all listed
- 2 then get all fipsCodes for all the non imported folderNames
   - traverse into Zips and listAsync all files and parse all fipsCodes
- 3 then insert each object into digimaps_parcel_imports
###
_defineImports = (digiMapsSettings, rootDir = DIGIMAPS.DIRECTORIES[0].name, endDir = DIGIMAPS.DIRECTORIES[2].name) -> Promise.try ->
    folderNamesToAdd = null
    importsToAdd = []
    _getClientFromDigiSettings(digiMapsSettings)
    .then (client) -> #step 1
        client.cwdAsync './' + rootDir
        .then (dir) ->
            logger.debug 'defineImports: step 1'
            client.listAsync()
            .then (ls) ->
                logger.debug 'defineImports: step 1 listing folderNames'
                #get the primary keys
                folderNames = ls.map (l) -> l.name
                #only get fipsCodes for the imports that have not been run
                _digiMapsImports.get().then (rows) ->
                    folderNamesToRemove = rows.map (r) -> r.folder_name
                    logger.debug "folderNamesToRemove: #{folderNamesToRemove}"
                    folderNamesToAdd = _.reject folderNames, (name) ->
                        _.contains folderNamesToRemove, name
                    logger.debug "defineImports: step 1, folderNamesToAdd: #{folderNamesToAdd}"

                    logger.debug "Nothing to add to import!!!!!" unless folderNamesToAdd?.length

        .then -> #step 2
            logger.debug 'defineImports: step 2'
            promises = []

            _getImport = (lPath, folderName, getClient) ->
                getClient.cwdAsync(lPath).then ->
                    getClient.pwdAsync().then (path) ->
                        logger.debug "pwd: #{path}"
                    getClient.listAsync()
                .then (ls) ->
                    fipsCodes = _fipsCodesFromListing(ls)
                    toImport =
                        folder_name: folderName
                        fips_codes:JSON.stringify fipsCodes
                        full_path: lPath

                    logger.debug "defineImports: step 2"
                    # logger.debug toImport
                    importsToAdd.push toImport

            for key, name of folderNamesToAdd
                fullPath = "/#{rootDir}/#{name}/#{endDir}"
                logger.debug "defineImports: step 2, fullPath: #{fullPath}"
                promises.push _getImport(fullPath, name, client)

            Promise.all promises
        .then -> #step 3
            logger.debug 'defineImports: step 3'
            logger.debug importsToAdd
            _digiMapsImports.insert(importsToAdd)
        .finally ->
            logger.debug "closing client"
            client.end()

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
                    hasFipsCode = _.contains _fipsCodesFromListing(ls), fipsCode
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
