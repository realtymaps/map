_ = require 'lodash'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('util:parcel')
dbs = require '../config/dbs'
{DataValidationError} = require '../utils/util.validation'
transforms = require '../utils/transforms/transform.parcel'


_toReplace = 'REPLACE_ME'


_formatParcel = (feature) -> Promise.try ->
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
      _formatParcel JSON.parse row.feature
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


prepRowForRawGeom = (row) ->
  if row.geometry.type == 'Point'
    row.geom_point_raw = dbs.get('normalized').raw("st_geomfromgeojson( ? )", JSON.stringify(row.geometry))
  else  # 'Polygon'
    row.geom_polys_raw = dbs.get('normalized').raw("ST_Multi(st_geomfromgeojson( ? ))", JSON.stringify(row.geometry))
  delete row.geometry


module.exports = {
  normalize
  prepRowForRawGeom
}
