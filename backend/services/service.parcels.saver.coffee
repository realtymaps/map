parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
parcelFetcher = require './service.parcels.fetcher.digimaps'
shp2json = require 'shp2jsonx'

module.exports = (fipsCode) ->
    parcelFetcher(fipsCode)
    .then (stream) ->
        #return json stream
        s = shp2json(stream)#.pipe(JSONStream.parse('*'))
        s.on 'data', (d) ->
            logger.debug d
        s
