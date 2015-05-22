parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
{DIGIMAPS} = require '../config/config'

JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
fs = require 'fs'



_createFtpClient = (url, account, password) ->

_getLatestParcelDirectory = (ftpClient) ->

_getFileName = (fipsCode) ->
  if Object.hasOwnProperty(DIGIMAPS.FILE, 'appendFipsCode') and DIGIMAPS.FILE.appendFipsCode
    return DIGIMAPS.FILE.name + fipsCode
  DIGIMAPS.FILE.name

_getParcelZipFile = (ftpClient, fipsCode) ->
  fileName = _getFileName(fipsCode)




module.exports =
