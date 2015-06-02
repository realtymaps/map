Promise = require "bluebird"
logger = require '../config/logger'
ftp = require 'ftp'
_ = require 'lodash'

DIGIMAPS =
    DIRECTORIES:[{name:"DELIVERIES"}, {name: "DMP_DELIVERY_", doParseDate:true}, {name:"ZIPS"}]
    FILE:{name:"Parcels_", appendFipsCode:true, ext:".zip"}

_createFtp = (url, account, password) ->
    c = Promise.promisifyAll(new ftp())
    opts =
        host:url
        user:account
        password: password

    logger.debug("new client connecting: #{JSON.stringify(opts)}")

    c.connect(opts)
    c.onAsync 'ready'
    .catch (err) ->
        logger.error(err)
        throw err
    .then ->
        logger.debug("new client connected")
        c

_getLatestDir = (client, dirObj) ->
    client.listAsync()
    .then (ls) ->
        return if !ls?.length
        ls = ls.map (l) -> l.name
        ls.sort()
        # logger.debug ls
        ret = ls[ls.length - 1]
        # logger.log("dirObj: #{dirObj.name}")
        # logger.log("ret: #{ret}")
        if ret.indexOf(dirObj.name) == -1
            throw 'latest directory name does not match'
        ret

_goToLatestDir = (client, directories = _.cloneDeep DIGIMAPS.DIRECTORIES) ->
    dig = ->
        dirObj = directories.shift()
        # logger.debug("dig")
        dirNamePromise = if dirObj?.doParseDate then _getLatestDir(client, dirObj) else Promise.resolve dirObj.name
        dirNamePromise.then (dirName) ->
            client.cwdAsync './' + dirName
            .then (dir) ->
                return client.pwdAsync() unless dir
                dir
            .then (dir) ->
                throw 'Not in the correct dirctory' if dir.indexOf(dirName) == -1
                dir
            .then ->
                if directories.length
                    return dig()
                return dirName
    dig()

_getFileName = (fipsCode) ->
    if DIGIMAPS.FILE?.appendFipsCode == true
        return DIGIMAPS.FILE.name + String(fipsCode) + DIGIMAPS.FILE.ext
    DIGIMAPS.FILE.name

_getParcelZipFileStream = (fipsCode, digiMapsSettings) ->
    if _.isFunction digiMapsSettings?.then
        promise = digiMapsSettings
    else
        {URL, ACCOUNT, PASSWORD} = digiMapsSettings
        promise = _createFtp(URL, ACCOUNT, PASSWORD)

    promise.then (client) ->
        fileName = _getFileName(fipsCode)
        logger.debug(fileName)
        _goToLatestDir(client)
        .then (dirName) ->
            logger.debug("downloading: #{fileName}")
            client.getAsync(fileName)
        .then (stream) ->
            logger.debug("download complete: #{fileName}")
            stream.on 'error', (err) ->
                logger.debug "stream error: #{err}"
                client.end()
                throw err
            stream.on 'close', ->
                logger.debug 'stream close'
                client.end()
            stream


module.exports = _getParcelZipFileStream
