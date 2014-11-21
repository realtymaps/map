sprintf = require('sprintf-js').sprintf
logger = require '../../config/logger'
errors = require './sql.errors'
geoStrings = require '../../../common/utils/util.geom.strings'
coordSys = require '../../../common/utils/enums/util.enums.map.coord_system'
sqlStrings = require '../../utils/util.sql.strings'
safeGen = require('../../utils/sql/util.sql.safegen')

AND = sqlStrings.AND
SELECTAll = sqlStrings.SELECTAll
SELECT = sqlStrings.SELECT
DISTINCT = sqlStrings.DISTINCT
_limit = '250'


tableName = 'parcels'

select = sprintf(SELECT, """
rm_property_id,
rm_inserted_time,
rm_modified_time,
parcelapn as apn,
fips,
sthsnum as stnum,
stdir,
ststname as stname,
stsuffix,
stcity,
ststate,
stzip,
stzip4,
xcoord as lon,
ycoord as lat,
addrscore,
#{geoStrings.postgisProcs.ST_AsGeoJSON}(geom_point) as geom_point,
#{geoStrings.postgisProcs.ST_AsGeoJSON}(geom_polys) as geom_polys
"""
, tableName)

selectPolys = sprintf(SELECT, """
#{DISTINCT("rm_property_id")}
rm_property_id,
stcity as city,
ststate as state,
#{geoStrings.postgisProcs.ST_AsGeoJSON}(geom_polys) as geom_polys
"""
, tableName)


# basic getAll function to take different selectors
getAll = (obj, nextCb, selector = select, limit = _limit, doLimit = true) ->
  throw new errors.SqlTypeError("bounds is not defined or not an array") if !obj.bounds? or !_.isArray obj.bounds

  tquery = selector

  if obj.bounds? and obj.bounds.length > 2
    doLimit = true
    tquery += """
      ST_WITHIN(geom_polys, ST_GeomFromText(#{geoStrings.multiPolygon(obj.bounds)}, #{coordSys.UTM}))
      """.space()
    connector = AND
  else
    #http://gis.stackexchange.com/questions/60700/postgis-select-by-lat-long-bounding-box
    tquery += """
      geom_polys && #{geoStrings.makeEnvelope(obj.bounds, coordSys.UTM)}
      """

  if doLimit
    tquery += " LIMIT #{limit}"

  logger.sql tquery

  tquery

getAllPolys = (queryOpts, next) ->
  getAll(queryOpts, next, selectPolys)

module.exports =
  all: (queryOpts, next) ->
    safeGen getAll, queryOpts, next

  allPolys: (queryOpts, next) ->
    safeGen getAllPolys, queryOpts, next


### THIS NEEDS TO BE REFACTORED, the whole connector stuff should be a function that automates the repetitiveness
        connector = AND
    if obj.type?
      tquery += connector + "use_code = '1' "
      connector = AND
    if obj.name?
      tquery += connector + "owner_name1 LIKE '%#{obj.name.toUpperCase()}%' "
      connector = AND
    if obj.soldwithin?
      tquery += connector + "sale1_date   >= (now() - '" + obj.soldwithin + "day'::INTERVAL)"
      connector = AND
    if obj.acres?
      acresMin = obj.acres[0]
      acresMax = obj.acres[1]
      unless acresMax is 0
        tquery += connector + "acres between " + acresMin + AND + acresMax
        connector = AND
      else
        tquery += connector + "acres >= " + acresMin
        connector = AND
    if obj.price?
      priceMin = obj.price[0]
      priceMax = obj.price[1]
      unless priceMax is 0
        tquery += connector + "sale1_amount between #{priceMin} AND #{priceMax} "
        connector = AND
      else
        tquery += connector + "sale1_amount >= " + priceMin
        connector = AND
    if obj.apn?
      tquery += connector + "parcel_id = '#{obj.apn}'"
      connector = AND
    if obj.city?
      tquery += connector + "owner_city = '#{obj.city}'"
      connector = AND
###