parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
parcelFetcher = require './service.parcels.fetcher.digimaps'
shp2json = require 'shp2jsonx'
_ = require 'lodash'

_getParcelJSON = (fipsCode) ->
    parcelFetcher(fipsCode)
    .then (stream) ->
        shp2json(stream)
        .pipe(JSONStream.parse('*'))

_uploadToParcelsDb = (fipsCode) ->
    _getParcelJSON(fipsCode)
    .then (stream) ->
        stream.on 'data', (d) ->
            #Upload each object to the parcels DB
            #some objects are points and others a polygons
            #one will be an insert and the next will be an update
            console.log typeof d
            console.log "isString: #{_.isString d}"



module.exports =
    getParcelJSON: _getParcelJSON
