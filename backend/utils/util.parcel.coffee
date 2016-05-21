_ = require 'lodash'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('util.parcel')
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
{DataValidationError} = require '../utils/util.validation'
transforms = require '../utils/transforms/transform.parcel'


formatParcel = (feature) -> Promise.try ->
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
    throw new DataValidationError('required', 'feature', feature)

  #match the db attributes
  obj = _.mapKeys feature.properties, (val, key) ->
    key.toLowerCase()

  obj.geometry = feature.geometry

  transforms.validateAndTransform(obj)


normalize = ({batch_id, rows, fipsCode, data_source_id, startTime}) ->
  stringRows = rows

  for row in stringRows
    do (row) ->
      #feature is a string, make it a JSON obj
      formatParcel JSON.parse row.feature
      .then (obj) ->
        # logger.debug obj

        if fipsCode
          obj.fips_code = fipsCode

        _.extend obj, {
          data_source_id
          batch_id
          rm_raw_id: row.rm_raw_id
        }
        #return a valid row
        row: obj
      .catch (error) ->
        #return an error object
        error: error
      .then (ret) ->

        # Regardless we extend a row or an error object with stats
        # and .. with rm_raw_id! This allows for less object defined
        # checking where rm_raw_id will always be defined.
        _.extend ret,
          rm_raw_id: row.rm_raw_id# dont forget about me :)
          stats: {
            data_source_id
            batch_id
            rm_raw_id: row.rm_raw_id
            up_to_date: startTime
          }

_toReplace = 'REPLACE_ME'

_fixTableName = (database, tableName) ->
  normStr = ''
  if database == 'norm' || database == 'normalized'
    normStr = 'norm'
    tableName = normStr + tableName.toInitCaps()
  tableName

_prepEntityForGeomReplace = (row) ->
  # logger.debug val.geometry
  toReplaceWith = "st_geomfromgeojson( '#{JSON.stringify(row.geometry)}')"
  toReplaceWith = "ST_Multi(#{toReplaceWith})" if row.geometry.type == 'Polygon'

  key = if row.geometry.type == 'Point' then 'geom_point_raw' else 'geom_polys_raw'

  delete row.geometry

  row[key] = _toReplace

  {row, toReplaceWith}

_insertOrUpdate = (method, {row, tableName, database}) ->
  method ?= 'insert'
  tableName = _fixTableName database, tableName
  {row, toReplaceWith} = _prepEntityForGeomReplace row

  q = tables.property[tableName]()[method](row)

  if method == 'update'
    q = q.where(rm_property_id: row.rm_property_id)

  raw = q.toString()
  raw = raw.replace("'#{_toReplace}'", toReplaceWith)
    .replace(/\\/g,'') #hack to deal with change_history and json knex issues

  logger.debug raw
  raw


insertParcelStr = _insertOrUpdate.bind(null, 'insert')

updateParcelStr = _insertOrUpdate.bind(null, 'update')

upsertParcelSqlString = ({row, tableName, database}) ->

  tableName = _fixTableName database, tableName
  {row, toReplaceWith} = _prepEntityForGeomReplace {row, tableName, database}

  q = sqlHelpers.upsert
    idObj: rm_property_id: row.rm_property_id
    entityObj: _.omit(row, 'rm_property_id'),
    dbFn: tables.property[tableName]

  raw = q.toString()
  raw = raw.replace(new RegExp("'#{_toReplace}'", "g"), toReplaceWith)

  logger.debug raw
  raw

module.exports = {
  formatParcel
  normalize
  upsertParcelSqlString
  insertParcelStr
  updateParcelStr
}
