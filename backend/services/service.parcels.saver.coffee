parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
parcelFetcher = require './service.parcels.fetcher.digimaps'
shp2json = require 'shp2jsonx'
_ = require 'lodash'
through = require 'through'

_formatParcel = (feature, geometryType) ->
    #match the db attributes
    obj = _.mapKeys feature.properties, (val, key) ->
        key.toLowerCase()
    obj.rm_property_id = obj.parcelapn + obj.fips + '_001'
    if geometryType == 'point'
        obj.geom_point_json = feature.geometry
    else
        obj.geom_polys_json = feature.geometry
    obj

_formatParcels = (featureCollection)  ->
    geomType = if featureCollection.fileName.indexOf 'Points' == -1 then 'polygon' else 'point'
    featureCollection.features.map (f) ->
        _formatParcel(f,geomType)

_getParcelJSON = (fipsCode) ->
    parcelFetcher(fipsCode)
    .then (stream) ->
        shp2json(stream)
        .pipe(JSONStream.parse('*'))

_getFormatedParcelJSON = (fipsCode) ->
    _getParcelJSON(fipsCode)
    .then (stream) ->
        write = (obj) ->
          @queue _formatParcels(obj)
        end = ->
          @queue null
        stream.pipe through(write, end)

_uploadToParcelsDb = (fipsCode) ->
    _getParcelJSON(fipsCode)
    .then (stream) ->
        stream.on 'data', (d) ->
            #Upload each object to the parcels DB
            #some objects are points and others a polygons
            #one will be an insert and the next will be an update
            objs = _formatParcels d
            parcelSvc.upsert objs

module.exports =
    getParcelJSON: _getParcelJSON
    getFormatedParcelJSON: _getFormatedParcelJSON
    uploadToParcelsDb: _uploadToParcelsDb
