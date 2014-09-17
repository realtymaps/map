###
 TODO DECISION, Many POSTGIS queries will be complex

 Is it worth even attempting to learn the bookshelf dsl (or search for bookshelf POSTGIS extensions)


 Original queries from the concept map
###

module.exports =
  all: (obj) ->
    tquery = """"
    select id, parcel_id, owner_name1,owner_name2,owner_name3,owner_name4,owner_name5,owner_city, owner_state, owner_zipcode,
    street_name, street_type, street_ord, street_num, zipcode, acres, sale1_amount,sale1_date,sale2_amount,sale2_date,sale3_amount,
    sale3_date,sale4_amount,sale4_date, use_code, total_value,total_taxes, lat, lng
    from county_data1_copy
    where
    """

    #var tquery = "select lat, lng from county_data1_copy where ";
    connector = ""
    if obj.polys?

      #tquery += "county_data1_copy.geom && ST_MakeEnvelope('"+obj.bounds[1]+"', '"+obj.bounds[0]+"','"+obj.bounds[3]+"', '"+obj.bounds[2]+"', 4326) ";
      tquery += """
      ST_Within(county_data1_copy.geom,ST_GeomFromText('MULTIPOLYGON(((-81.799607 26.119916,-81.792183 26.119647,-81.789565 26.115909,
      -81.789823 26.112556,-81.796045 26.111863,-81.799908 26.112749,-81.802611 26.118606,-81.799607 26.119916)),((-81.792097 26.104502,
      -81.795058 26.102074,-81.797118 26.098837,-81.792397 26.098105,-81.787333 26.100263,-81.786819 26.103616,-81.789050 26.104849,-81.792097 26.104502)))', 4326))
      """
      connector = " AND "
    else if obj.bounds?
      tquery += "county_data1_copy.geom && ST_MakeEnvelope('" + obj.bounds[1] + "', '" + obj.bounds[0] + "','" + obj.bounds[3] + "', '" + obj.bounds[2] + "', 4326) "
      connector = " AND "
    if obj.type?
      tquery += connector + "use_code = '1' "
      connector = " AND "
    if obj.name?
      tquery += connector + "owner_name1 LIKE '%" + decodeURIComponent(obj.name).toUpperCase() + "%' "
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
        tquery += connector + "sale1_amount between " + priceMin + " AND " + priceMax
        connector = " AND "
      else
        tquery += connector + "sale1_amount >= " + priceMin
        connector = " AND "
    if obj.apn?
      tquery += connector + "parcel_id = '" + decodeURIComponent(obj.apn) + "'"
      connector = " AND "
    tquery += " LIMIT 500"
    console.log tquery
    tquery

allByAddressNumbers: (obj) ->
  tquery = """
  select id, parcel_id, owner_name1,owner_name2,owner_name3,owner_name4,owner_name5,owner_city, owner_state,
  owner_zipcode, street_name, street_type, street_ord, street_num, zipcode, acres, sale1_amount,sale1_date,
  sale2_amount,sale2_date,sale3_amount,sale3_date,sale4_amount,sale4_date, lat, lng
  from county_data1_copy
  where
  """

  #var tquery = "select lat, lng from county_data1_copy where ";
  tquery += "county_data1_copy.geom && ST_MakeEnvelope('" + obj.bounds[1] + "', '" + obj.bounds[0] + "','" + obj.bounds[3] + "', '" + obj.bounds[2] + "', 4326) "  if obj.bounds?
  tquery += "LIMIT 500"
  console.log tquery
  tquery


#third party accessors value (digMaps)
#apn is a number that is unique per county per property
allByApn: (obj) ->
  tquery = """
  select id, parcel_id, owner_name1,owner_name2,owner_name3,owner_name4,owner_name5,owner_city,
  owner_state, owner_zipcode, street_name, street_type, street_ord, street_num, zipcode, acres, sale1_amount,
  sale1_date,sale2_amount,sale2_date,sale3_amount,sale3_date,sale4_amount,sale4_date, use_code,
  total_value,total_taxes, lat, lng
  from county_data1_copy
  where
   """

  #var tquery = "select lat, lng from county_data1_copy where ";
  connector = ""
  if obj.bounds?
    tquery += "county_data1_copy.geom && ST_MakeEnvelope('" + obj.bounds[1] + "', '" + obj.bounds[0] + "','" + obj.bounds[3] + "', '" + obj.bounds[2] + "', 4326) "
    connector = " AND "
  if obj.apn?
    tquery += connector + "parcel_id = '" + decodeURIComponent(obj.apn) + "'"
    connector = " AND "
  console.log tquery
  tquery
