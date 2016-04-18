_ = require 'lodash'
{crsFactory} = require '../../common/utils/enums/util.enums.map.coord_system'
logger = require('../config/logger').spawn('util.parcel')
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'

formatParcel = (feature) ->
  ###
    parcelapn: '48066001',
    fips: '06009',
    sthsnum: '61',
    stdir: 'S',
    ststname: 'WALLACE LAKE',
    stsuffix: 'DR',
    stquadrant: null,
    stunitprfx: null,
    stunitnum: null,
    stcity: 'VALLEY SPRINGS',
    ststate: 'CA',
    stzip: '95252',
    stzip4: null,
    xcoord: '-120.972668',
    ycoord: '38.196870',
    geosource: 'PARCELS',
    addrscore: '3',
    rm_property_id: '4806600106009_001',
  geometry:
   type: 'Point',
     coordinates: [ -120.97266826902195, 38.196869881471976 ],
     crs: { type: 'name', properties: {}
  ###
  if !feature?
    throw new Error 'feature undefined'
  if !feature?.geometry?
    logger.error feature
    throw new Error 'feature.geometry undefined'

  #match the db attributes
  obj = _.mapKeys feature.properties, (val, key) ->
    key.toLowerCase()
  obj.rm_property_id = obj.parcelapn + obj.fips + '_001'
  obj.geometry = feature.geometry
  obj.geometry.crs = crsFactory()
  obj

_trimmedPicks = [
  'fips_code'
  'rm_property_id'
  'street_address_num'
  'street_unit_num'
  'geometry'
]

formatTrimmedParcel = (feature) ->
  feature = formatParcel(feature)
  feature.street_address_num = feature.sthsnum
  feature.street_unit_num = feature.stunitnum
  feature.fips_code = feature.fips
  _.pick feature, _trimmedPicks


normalize = ({batch_id, rows, fipsCode, data_source_id}) ->
  stringRows = rows
  for r in stringRows
    do (r) ->
      #feature is a string, make it a JSON obj
      obj = formatTrimmedParcel JSON.parse r.feature
      # logger.debug obj

      if fipsCode
        obj.fips_code = fipsCode

      _.extend obj, {
        data_source_id
        batch_id
      }
      obj

_toReplace = 'REPLACE_ME'

_fixTableName = (database, tableName) ->
  normStr = ''
  if database == 'norm' || database == 'normalized'
    normStr = 'norm'
    tableName = normStr + tableName.toInitCaps()
  tableName

_prepEntityForGeomReplace = ({row, tableName, database}) ->
  # logger.debug val.geometry
  toReplaceWith = "st_geomfromgeojson( '#{JSON.stringify(row.geometry)}')"
  toReplaceWith = "ST_Multi(#{toReplaceWith})" if row.geometry.type == 'Polygon'

  key = if row.geometry.type == 'Point' then 'geom_point_raw' else 'geom_polys_raw'

  delete row.geometry

  row[key] = _toReplace

  {row, toReplaceWith}

_insertOrUpdate = ({row, method, tableName, database}) ->
  method ?= 'insert'
  tableName = _fixTableName database, tableName
  {row, toReplaceWith} = _prepEntityForGeomReplace {row, tableName, database}

  q = tables.property[tableName]()[method](row)

  if method == 'update'
    q = q.where(rm_property_id: row.rm_property_id)

  raw = q.toString()
  raw = raw.replace("'#{_toReplace}'", toReplaceWith)

  logger.debug raw
  raw


insertParcelStr = (opts) ->
  opts.method = 'insert'
  _insertOrUpdate opts

updateParcelStr = (opts) ->
  opts.method = 'update'
  _insertOrUpdate opts

upsertParcelSqlString = ({row, tableName, database}) ->

  tableName = _fixTableName database, tableName
  {row, toReplaceWith} = _prepEntityForGeomReplace {row, tableName, database}

  q = sqlHelpers.upsert
    doWrapPromise: false
    idObj: rm_property_id: row.rm_property_id
    entityObj: _.omit(row, 'rm_property_id'),
    dbFn: tables.property[tableName]

  raw = q.toString()
  raw = raw.replace(new RegExp("'#{_toReplace}'", "g"), toReplaceWith)

  logger.debug raw
  raw

module.exports = {
  formatParcel
  formatTrimmedParcel
  normalize
  upsertParcelSqlString
  insertParcelStr
  updateParcelStr
}
