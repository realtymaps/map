logger = require '../../config/logger'
errors = require './sql.errors'

###
 TODO DECISION, Many POSTGIS queries will be complex

 Is it worth even attempting to learn the bookshelf dsl (or search for bookshelf POSTGIS extensions)


 Original queries from the concept map
###

### ignored fields
  geom, lng_old, lat_old
###
select =
    """select
    id,parcel_id,zipcode,
    owner_name1,owner_name2,owner_name3,
    owner_name4,owner_name5,owner_city,
    owner_state,owner_zipcode,legal1,
    legal2,legal3,legal4,
    street_name,street_type,street_ord,
    street_num,block,lot,acres,
    cur_yr_ass,sale1_date,sale1_amount,
    sale2_date,sale2_amount,
    sale3_date,sale3_amount,
    sale4_date,sale4_amount,
    use_code,subcondo,section,
    township,range,strap,parcel,
    land_value,adjusted_value,
    improved_value,total_value,
    total_taxable,adjusted_ex_amount,
    hms_ex_amount,wh_ex_amount,
    wid_ex_amount,bld_ex_amount,
    dis_ex_amount,total_taxes,
    lat as latitude, lng as longitude
    from county_data1_copy
    where
    """.space()

module.exports =
  all: (obj) ->
    tquery = select

    if obj.bounds? and obj.bounds.length > 2
      #  ( lon0 lat0, lonN latN, lon0 lat0 )
      isFirst = true
      boundsStr = _.reduce obj.bounds, (all, next) ->
        unless isFirst
          "#{all} #{next[0]} #{next[1]}, "
        else
          isFirst = false
          "#{all[1]} #{all[0]}, #{next[1]} #{next[0]}, "
      boundsStr += "#{obj.bounds[0][1]} #{obj.bounds[0][0]}"
      tquery += """
      ST_WITHIN(county_data1_copy.geom,ST_GeomFromText('MULTIPOLYGON(((#{boundsStr})))', 4326))
      """.space()
      connector = " AND "
    else
      throw new errors.SqlTypeError("bounds is not defined or not an array") if !obj.bounds? or !_.isArray obj.bounds
      #ST_MakeEnvelope(minLon, minLat, maxLon, maxLat, 4326);
      #http://gis.stackexchange.com/questions/60700/postgis-select-by-lat-long-bounding-box
      tquery += """
      county_data1_copy.geom && ST_MakeEnvelope(#{obj.bounds[0][1]},
      #{obj.bounds[1][0]},#{obj.bounds[1][1]}, #{obj.bounds[0][0]}, 4326)
      """

      connector = " AND "
    if obj.type?
      tquery += connector + "use_code = '1' "
      connector = " AND "
    if obj.name?
      tquery += connector + "owner_name1 LIKE '%#{obj.name.toUpperCase()}%' "
      connector = " AND "
    if obj.soldwithin?
      tquery += connector + "sale1_date   >= (now() - '" + obj.soldwithin + "day'::INTERVAL)"
      connector = " AND "
    if obj.acres?
      acresMin = obj.acres[0]
      acresMax = obj.acres[1]
      unless acresMax is 0
        tquery += connector + "acres between " + acresMin + " AND " + acresMax
        connector = " AND "
      else
        tquery += connector + "acres >= " + acresMin
        connector = " AND "
    if obj.price?
      priceMin = obj.price[0]
      priceMax = obj.price[1]
      unless priceMax is 0
        tquery += connector + "sale1_amount between #{priceMin} AND #{priceMax} "
        connector = " AND "
      else
        tquery += connector + "sale1_amount >= " + priceMin
        connector = " AND "
    if obj.apn?
      tquery += connector + "parcel_id = '#{obj.apn}'"
      connector = " AND "
    if obj.city?
      tquery += connector + "owner_city = '#{obj.city}'"
      connector = " AND "

    tquery += " LIMIT 500"

    logger.sql tquery

    tquery
