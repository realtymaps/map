_ = require 'lodash'
Promise = require 'bluebird'
logger = require('../config/logger').spawn('util:parcel')
dbs = require '../config/dbs'
{DataValidationError} = require '../utils/util.validation'
transforms = require '../utils/transforms/transform.parcel'
require '../../common/extensions/lodash'
errorUtils = require './errors/util.error.partiallyHandledError'


_formatParcel = (feature) -> Promise.try ->
  ### from README_REALTYMAPSTER.txt

  PARCELPOINTS FILE DESCRIPTION :

     CONTENTS :

          Parcel centroid with tax identifier. Parcel APN is a common key between
          parcel file and parcel point file.

     FILE FORMAT :
              ESRI Shapefle

     FILE NAME :

          ParcelPoints_<COUNTY FIPS>.shp
          ParcelPoints_<COUNTY FIPS>.shx
          ParcelPoints_<COUNTY FIPS>.prj
          ParcelPoints_<COUNTY FIPS>.dbf

     FIELDS/CONTENTS :

          FID        (OID)                #Unique feature ID in ESRI Shapefile.
          SHAPE      (Geometry)           #Parcel boundary geometry (point) in ESRI Shapefile.
          PARCLAPN   (String[50])         #The assessor's parcel number (APN) is a number assigned
                                           to parcels of real property by the tax assessor of a
                                           particular jurisdiction for purposes of identification
                                           and record-keeping. The assigned number is unique within
                                           the particular jurisdiction
          FIPS        (String[5])         #The 5-digit Federal Information Processing Code for the
                                           State and County.
          STHSNUM     (String[10])        #Site house number
          STDIR       (String[2])         #Site directional (N,S,E,W,NE,etc)
          STSTNAME    (String[28])        #Site street Name
          STSUFFIX    (String[4])         #Site suffix (Ave,Dr,Ct,etc.)
          STQUADRANT  (String[2])         #Site Quadrant (N,S,E,NE,etc)
          STUNITPRFX  (String[4])         #Site Unit prefix (Suite,Apt, Unit etc)
          STUNITNUM   (String[8])         #Site Unit number
          STCITY      (String[28])        #Site city
          STSTATE     (String[2])         #site State
          STZIP       (String[5])         #Site Zipcode
          STZIP4      (String[4])         #Site zip_4 code
          XCOORD      (String[11])        #X coordinate
          YCOORD      (String[11])        #Y coordinate
          GEOSOURCE   (String[24])        #Geo Source (source of geocoded location)
          ADDRSCORE   (String[1])         #Address Score. 1-5 with 5 being best/ideal score


     COORDINATE SYSTEM & DATUM :

          Geographic Coordinate System, North American Datum of 1983

     Linking:

          Links to parcels via Parcel_APN. ParcelPoints.[PARCELAPN] = ParceLS.[APN]
  ###

  ### Example:
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
  .then (obj) ->
    fine = logger.spawn('fine')
    obj = _.cleanObject(obj)
    logger.debug -> '@@@@ parcel transformed @@@@'
    fine.debug -> obj
    obj


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
  # mutates row object only
  prepLogger = logger.spawn('prepRowForRawGeom')
  try
    #NOTE: If we were to simplify our geometries across the board on import
    # it should be done here , SIMPLIFY_TOL = .000002
    if !row.geometry?
      prepLogger.debug "@@@@@ WHAT THE HECK? @@@@@"
      prepLogger.debug -> row
      return

    if row.geometry.type == 'Point'
      row.geometry_center_raw = dbs.get('normalized')
        .raw("st_geomfromgeojson( ? )", JSON.stringify(row.geometry))
      row.geometry_center = row.geometry
      delete row.geometry
    else if row.geometry.type == 'Polygon' || row.geometry.type == 'MultiPolygon'
      row.geometry_raw = dbs.get('normalized')
        .raw("ST_Multi(st_geomfromgeojson( ? ))", JSON.stringify(row.geometry))
      row.geometry_center_raw = dbs.get('normalized')
        .raw("st_centroid(ST_Multi(st_geomfromgeojson( ? )))", JSON.stringify(row.geometry))
      row.geometry_center = dbs.get('normalized')
        .raw("ST_AsGeoJSON(st_centroid(ST_Multi(st_geomfromgeojson( ? ))))::jsonb", JSON.stringify(row.geometry))
    else
      logger.warn("Unknown geometry.type: #{row.geometry.type}")

    return

  catch error
    throw new errorUtils.PartiallyHandledError error, 'util.parcels.prepRowForRawGeom failed'


module.exports = {
  normalize
  prepRowForRawGeom
}
