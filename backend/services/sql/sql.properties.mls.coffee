###
 TODO DECISION, Many POSTGIS queries will be complex

 Is it worth even attempting to learn the bookshelf dsl (or search for bookshelf POSTGIS extensions)
  
 JWI: We don't need to use bookshelf, but we should use Knex.  Knex allows raw queries (and partial queries) so it
      doesn't matter if it "handles" GIS.  Really, Knex is just a SQL builder -- it does exactly what's happening below,
      but in a cross-db way, with protection against SQL injection, and yielding easier to read code.  You can even
      take the resulting query object and use .toString() to get the SQL string.


 Original queries from the concept map
###

select =
    """
    select id, parcel_id, mls_number, full_address, street_num, street_name, street_type, street_ord, city, state, zipcode,
    list_price, beds, baths, baths_half, living_area, year_built, acres, listing_date, lat, lng
    from temp_mls_data2
    where
    """.space()

module.exports =
  all: (obj) ->
    tquery = select

    #var tquery = "select lat, lng from county_data1_copy where ";
    if obj.bounds?
      tquery += "temp_mls_data2.geom && ST_MakeEnvelope('" + obj.bounds[1] + "', '" + obj.bounds[0] + "','" +
        obj.bounds[3] + "', '" + obj.bounds[2] + "', 4326) "
    if obj.name?
      tquery += "AND owner_name1 LIKE '%'" + decodeURIComponent(obj.name).toUpperCase() + "'%' "
    if obj.acres?
      acresMin = obj.acres[0]
      acresMax = obj.acres[1]
      unless acresMax is 0
        tquery += " AND acres between " + acresMin + " AND " + acresMax
      else
        tquery += " AND acres >= " + acresMin
    if obj.price?
      priceMin = obj.price[0]
      priceMax = obj.price[1]
      unless priceMax is 0
        tquery += " AND list_price between " + priceMin + " AND " + priceMax
      else
        tquery += " AND list_price >= " + priceMin

    #TODO add in function for Half Beds
    if obj.beds?
      bedsMin = obj.price[0]
      bedsMax = obj.price[1]
      unless bedsMax is 0
        tquery += " AND beds between " + bedsMin + " AND " + bedsMax
      else
        tquery += " AND beds >= " + bedsMin

    #TODO add in function for Half Baths
    if obj.baths?
      bathsMin = obj.price[0]
      bathsMax = obj.price[1]
      unless bedsMax is 0
        tquery += " AND baths between " + bathsMin + " AND " + bathsMax
      else
        tquery += " AND baths >= " + bathsMin
    console.log tquery
    tquery += " LIMIT 500"
    tquery
