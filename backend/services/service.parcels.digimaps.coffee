parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
{DIGIMAPS} = require '../config/config'

JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
ftp = require 'ftp'

_createFtp = (url, account, password) ->
    c = Promise.promisifyAll(new ftp())
    c.connectAsync
        host:url
        user:account
        password: password
    .then ->
        c

_getLatestDir = (client, dirObj) ->
    client.listAsync()
    .then (ls) ->
        return if !ls?.length
        ls.sort()
        ret = ls[ls.length - 1]
        # console.log("dirObj: #{dirObj.name}")
        # console.log("ret: #{ret}")
        if(ret.indexOf(dirObj.name) == -1)
            throw('latest directory name does not match')
        ret

_goToLatestDir = (client, directories = _.cloneDeep DIGIMAPS.DIRECTORIES) ->
    dig = ->
        dirObj = directories.shift()
        dirNamePromise = if dirObj?.doParseDate then _getLatestDir(client, dirObj) else Promise.resolve dirObj.name
        dirNamePromise.then (dirName) ->
            client.cwdAsync './' + dirName
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

_getParcelZipFileStream = (fipsCode, clientPromise = _createFtp(DIGIMAPS.URL, DIGIMAPS.ACCOUNT, DIGIMAPS.PASSWORD)) ->
    clientPromise
    .then (client) ->
        fileName = _getFileName(fipsCode)
        # console.log(fileName)
        _goToLatestDir(client)
        .then (dirName) ->
            client.getAsync(fileName) ##promise wrapped stream


module.exports = _getParcelZipFileStream
