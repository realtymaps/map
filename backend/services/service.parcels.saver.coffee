db = require('../config/dbs').properties
parcelSvc = require './service.properties.parcels'
Promise = require "bluebird"
logger = require '../config/logger'
JSONStream = require 'JSONStream'
{geoJsonFormatter} = require '../utils/util.streams'
parcelFetcher = require './service.parcels.fetcher.digimaps'
{WGS84, UTM} = require '../../common/utils/enums/util.enums.map.coord_system'
shp2json = require 'shp2jsonx'
_ = require 'lodash'
through = require 'through'

_toReplace = "REPLACE_ME"

_formatParcel = (feature) ->
    #match the db attributes
    obj = _.mapKeys feature.properties, (val, key) ->
        key.toLowerCase()
    obj.rm_property_id = obj.parcelapn + obj.fips + '_001'
    obj.geometry = feature.geometry
    obj.geometry.crs =
        type: "name"
        properties:
            name: "EPSG:26910"
    obj

_formatParcels = (featureCollection)  ->
    featureCollection.features.map (f) ->
        _formatParcel(f)

_getParcelJSON = (fipsCode, digimapsSetings) ->
    parcelFetcher(fipsCode, digimapsSetings)
    .then (stream) ->
        shp2json(stream)
        .pipe(JSONStream.parse('*'))

_getFormatedParcelJSON = (fipsCode, digimapsSetings) ->
    _getParcelJSON(fipsCode, digimapsSetings)
    .then (stream) ->
        write = (obj) ->
          @queue _formatParcels(obj)
        end = ->
          @queue null
        stream.pipe through(write, end)

_fixGeometrySql = (geomType, val, method = 'insert') ->
    # logger.debug val.geometry
    toReplaceWith = "st_geomfromgeojson( '#{JSON.stringify(val.geometry)}')"
    toReplaceWith = "ST_Multi(#{toReplaceWith})" if geomType == 'polygon'
    delete val.geometry
    key = if geomType == 'point' then 'geom_point' else 'geom_polys'
    val[key] = _toReplace
    q = parcelSvc.rootDb()[method](val)
    q = q.where(rm_property_id: val.rm_property_id) if method == 'update'
    raw = q.toString()
    raw.replace("'#{_toReplace}'", toReplaceWith)


_execRawQuery = (geomType, val, method = 'insert') ->
    raw = _fixGeometrySql(geomType,val, method)
    # logger.debug raw
    db.knex.transaction (trx) ->
        q = trx.raw(raw)
        # if method == 'update'
        #     logger.debug "\n\n"
        #     logger.debug q.toString()
        #     logger.debug "\n\n"
        q

_uploadToParcelsDb = (fipsCode, digimapsSetings) ->
    _getParcelJSON(fipsCode, digimapsSetings)
    .then (stream) ->
        new Promise (resolve, reject) ->
          stream.on 'error', reject
          stream.on 'data', (featureCollection) ->
              #Upload each object to the parcels DB
              #some objects are points and others a polygons
              #one will be an insert and the next will be an update
              # logger.debug featureCollection.fileName
              geomType = if featureCollection.fileName.indexOf('Points') != -1 then 'point' else 'polygon'
              logger.debug geomType
              coll = _formatParcels featureCollection
              inserts = {}
              updates = {}
              coll.forEach (val)  ->
                  return unless val?.parcelapn#GTFO we cant make a valid rm_property_id with no apn
                  insert = ->
                      return if inserts?[val.rm_property_id]
                      inserts[val.rm_property_id] = true
                      _execRawQuery(geomType, val)
                  update = (old) ->
                      return if updates?[val.rm_property_id]
                      updates[val.rm_property_id] = true
                      updateObj = _.merge({},old, val)
                      # logger.debug "\n\n"
                      # logger.debug updateObj
                      # logger.debug "\n\n"
                      _execRawQuery(geomType, updateObj, 'update')
                      # _update(geomType, updateObj)
                  parcelSvc.upsert val, insert, update
              if geomType == 'polygon'
                  logger.debug 'done kicking off insert/updates'
                  db.knex.raw("SELECT dirty_materialized_view('parcels', FALSE);")
                  .catch (err) ->
                    reject(err)
                  .then  ->
                    resolve()
module.exports =
    getParcelJSON: _getParcelJSON
    getFormatedParcelJSON: _getFormatedParcelJSON
    uploadToParcelsDb: _uploadToParcelsDb
