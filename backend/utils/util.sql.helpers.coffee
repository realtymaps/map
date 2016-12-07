_ = require 'lodash'
coordSys = require '../../common/utils/enums/util.enums.map.coord_system'
Promise = require 'bluebird'
sqlColumns = require('./util.sql.columns')
logger = require('../config/logger').spawn('utils:sql.helpers')
dbs = require("../config/dbs")
clone = require 'clone'
ExpectedSingleRowError =  require '../utils/errors/util.error.expectedSingleRow'
require '../../common/extensions/strings'

# MARGIN IS THE PERCENT THE BOUNDS ARE EXPANDED TO GRAB Extra Data around the view
_MARGIN = .25

_flattenLonLatImpl = (all, next) ->
  all.bindings.push(next.lon, next.lat)
  all.markers += ', ?, ?'
  return all

_flattenLonLat = (bounds) ->
  # flatten the last point as the initial value for reduce
  _.reduce bounds, _flattenLonLatImpl,
    bindings: [bounds[bounds.length-1].lon, bounds[bounds.length-1].lat]
    markers: '?, ?'

_whereRawSafe = (query, rawSafe) ->
  query.whereRaw rawSafe.sql, rawSafe.bindings

_orWhereRawSafe = (query, rawSafe) ->
  query.orWhere ()-> _whereRawSafe(@, rawSafe)

_orderByRawSafe = (query, rawSafe) ->
  query.orderByRaw rawSafe.sql, rawSafe.bindings

columns = sqlColumns.basicColumns

_getPartialPoint = (objOrArray, arrayDex, param) ->
  if _.isArray(objOrArray) then objOrArray[arrayDex] else objOrArray[param]

_getLat = (objOrArray) ->
  _getPartialPoint(objOrArray, 0, 'lat')

_getLon = (objOrArray) ->
  _getPartialPoint(objOrArray, 1, 'lon')

whereInBounds = (query, column, bounds) ->
  results = {}
  if bounds.length > 2
    # it must be a user-specified boundary
    boundsFlattened = _flattenLonLat(bounds)
    results.sql = "ST_WITHIN(#{column}, ST_GeomFromText(MULTIPOLYGON(((#{boundsFlattened.markers}))), #{coordSys.UTM}))"
    results.bindings = boundsFlattened.bindings
  else
    neLat = _getLat(bounds[0])
    neLon = _getLon(bounds[0])

    swLat = _getLat(bounds[1])
    swLon = _getLon(bounds[1])

    # it's the whole map, so let's put a margin on each side
    minLon = Math.min(neLon, swLon)
    maxLon = Math.max(neLon, swLon)
    marginLon = (maxLon - minLon)*_MARGIN
    minLat = Math.min(neLat, swLat)
    maxLat = Math.max(neLat, swLat)
    marginLat = (maxLat - minLat)*_MARGIN

    results.sql = "#{column} && ST_MakeEnvelope(?, ?, ?, ?, #{coordSys.UTM})"
    results.bindings = [ minLon-marginLon, minLat-marginLat, maxLon+marginLon, maxLat+marginLat ]
  _whereRawSafe query, results

whereIntersects = (query, geoPointJson, column = 'geometry_raw') ->
  results =
    sql: "ST_INTERSECTS(ST_GeomFromGeoJSON(?::text), #{column})"
    bindings: [geoPointJson]

  _whereRawSafe query, results
  query.raw = query.toString().replace(/\//g,'')#terrible hack for knex.. getting tired of doing this
  query

getClauseString = (query, remove = /.*where/) ->
  'WHERE '+ query.toString().replace(remove,'')

_whereInArrayToValues = (values) ->
  if Array.isArray values
    return values

  if !values?
    values = []
  else
    values = [values]

whereIn = (query, column, values) ->
  values =_whereInArrayToValues(values)
  # this logic is necessary to avoid SQL parse errors
  if values.length == 0
    query.whereRaw('FALSE')
  else if values.length == 1
    query.where(column, values[0])
  else
    query.whereIn(column, values)

orWhereIn = (query, column, values) ->
  query.orWhere () -> whereIn(@, column, values)

whereNotIn = (query, column, values) ->
  values =_whereInArrayToValues(values)
  # this logic is necessary to avoid SQL parse errors
  if values.length == 0
    query.whereRaw('TRUE')
  else if values.length == 1
    query.where(column, '!=', values[0])
  else
    query.whereNotIn(column, values)

orWhereNotIn = (query, column, values) ->
  query.orWhere () -> whereNotIn(@, column, values)

# iterate through entity object, and append either a `where` or `whereIn` clause based
# on whether that field value is an array
# Note: entity is a map of columns->values
whereAndWhereIn = (query, entity, isOr = false) ->
  maybeAppendOr = (clause) ->
    if isOr
      'or' + clause.toInitCaps(false)
    else
      clause

  for column, value of entity
    if Array.isArray(value)
      query = module.exports[maybeAppendOr("whereIn")](query, column, value)
    else
      query = query[maybeAppendOr('where')](column, value)
  query

orWhereAndWhereIn = (query, entity) -> whereAndWhereIn(query, entity, true)


between = (query, column, min, max) ->
  if min and max
    query.whereBetween(column, [min, max])
  else if min
    query.where(column, '>=', min)
  else if max
    query.where(column, '<=', max)

ageOrDaysFromStartToNow = (query, listingAge, beginDate, operator, val) ->
  _whereRawSafe query,
    sql: "#{sqlColumns.ageOrDaysFromStartToNow(listingAge, beginDate)} #{operator} ?"
    bindings: [ val ]

orderByDistanceFromPoint = (query, column, point) ->
  # order by distance from point
  # http://boundlessgeo.com/2011/09/indexed-nearest-neighbour-search-in-postgis/
  #geom <-> st_setsrid(st_makepoint(-90,40),4326)
  _orderByRawSafe query,
    sql: "#{column} <-> st_setsrid(st_makepoint(?,?),#{coordSys.UTM})"
    bindings: [point.longitude, point.latitude]

allPatternsInAnyColumn = (query, patterns, columns) ->
  patterns.forEach (pattern) ->
    query.where () ->
      subquery = @
      columns.forEach (column) ->
        _orWhereRawSafe subquery,
          sql: "#{column} ~* ?"
          bindings: [ pattern ]

select = (knex, which, passedFilters=null, prepend='') ->
  prepend += ' ' if prepend?
  extra = ''
  if passedFilters
    extra = ", #{passedFilters} as \"passedFilters\""
  knex.select(knex.raw(prepend + columns[which] + extra))
  knex

singleRow = (rows) -> Promise.try ->
  if !rows?.length
    return null
  return rows[0]

expectSingleRow = (rows, opts={}) ->
  if !rows?.length
    throw new ExpectedSingleRowError({quiet: opts.quiet}, 'Expected a single result and rows are empty!')
  if !rows[0]?
    throw new ExpectedSingleRowError({quiet: opts.quiet}, "Expected a single result and row is #{rows[0]}")  # undefined or null
  return rows[0]

isUnique = (tableFn, whereClause, id, name = 'Entity') ->
  query = tableFn().where(whereClause).count()

  query = query.whereNot(id:id) if id?

  logger.debug -> query.toString()

  query.then singleRow
  .then (row) ->
    if row.count > 0
      return Promise.reject new Error("#{name} already exists")
    true

safeJsonArray = (arr) ->
  # this function is minor a hack to deal with the fact that knex can't easily distinguish between a PG-array and a
  # JSON array when serializing to SQL, plus to ensure we get a db-NULL instead of a JSON null
  if !arr?
    return arr
  JSON.stringify(arr)

safeJsonEntity = (entity) ->
  # this function is minor a hack to deal with the fact that knex can't easily distinguish between a PG-array and a
  # JSON array when serializing to SQL, plus to ensure we get a db-NULL instead of a JSON null
  if typeof(entity) != 'object'
    return entity
  result = _.mapValues entity, (val) ->
    if _.isArray(val)
      return JSON.stringify(val)
    return val

sqlizeColName = (fullName) ->
  fullName.split('.').map (name) ->
    '"' + name + '"'
  .join('.')

buildQuery = ({knex, entity, orHash}) ->
  query = knex

  if !Object.keys(entity).length #GTFO
    return query.where({})

  clonedEntity = clone entity

  #iterate to build query and omit entity keys all in one
  for key, val of clonedEntity
    do (key, val) ->
      if _.isArray val
        if orHash?[key]?
          query = orWhereIn(knex, key, val)
        else
          query = whereIn(knex, key, val)
        delete clonedEntity[key]

  if Object.keys(clonedEntity).length
    return query.where(clonedEntity)

  query


buildRawBindings = (obj, opts={}) ->
  colPlaceholders = []
  colBindings = []
  valPlaceholders = []
  valBindings = []
  for k,v of obj
    if v == undefined
      # an undefined value should be explicitly skipped / not set
      continue
    colPlaceholders.push('??')
    colBindings.push(k)
    valPlaceholders.push('?')
    if v?
      valBindings.push(v)
    else  # v == null
      if opts.defaultNulls
        valBindings.push(dbs.connectionless.raw('DEFAULT'))
      else
        valBindings.push(dbs.connectionless.raw('NULL'))
  cols:
    placeholder: colPlaceholders.join(', ')
    bindings: colBindings
  vals:
    placeholder: valPlaceholders.join(', ')
    bindings: valBindings


# Static function that produces an upsert query string given ids and entity of model.
buildUpsertBindings = ({idObj, entityObj, conflictOverrideObj, tableName}) ->
  id = buildRawBindings(idObj, defaultNulls: true)
  entity = buildRawBindings(_.omit(entityObj, Object.keys(idObj)))
  conflictEntity = buildRawBindings(_.extend(_.omit(entityObj, Object.keys(idObj)), conflictOverrideObj))

  # postgresql templates for raw query (no real native knex support yet: https://github.com/tgriesser/knex/issues/1121)
  if conflictEntity.cols.placeholder
    templateStr = """
     INSERT INTO ?? (#{id.cols.placeholder}, #{entity.cols.placeholder})
      VALUES (#{id.vals.placeholder}, #{entity.vals.placeholder})
      ON CONFLICT (#{id.cols.placeholder})
      DO UPDATE SET (#{conflictEntity.cols.placeholder}) = (#{conflictEntity.vals.placeholder})
      RETURNING #{id.cols.placeholder}
    """
  else if entity.cols.placeholder
    templateStr = """
     INSERT INTO ?? (#{id.cols.placeholder}, #{entity.cols.placeholder})
      VALUES (#{id.vals.placeholder}, #{entity.vals.placeholder})
      ON CONFLICT (#{id.cols.placeholder})
      DO NOTHING
      RETURNING #{id.cols.placeholder}
    """
  else
    templateStr = """
     INSERT INTO ?? (#{id.cols.placeholder})
      VALUES (#{id.vals.placeholder})
      ON CONFLICT (#{id.cols.placeholder})
      DO NOTHING
      RETURNING #{id.cols.placeholder}
    """

  sql: templateStr.replace(/\n/g,'').replace(/\s+/g,' ')
  bindings: [tableName].concat(id.cols.bindings, entity.cols.bindings, id.vals.bindings, entity.vals.bindings, id.cols.bindings, conflictEntity.cols.bindings, conflictEntity.vals.bindings, id.cols.bindings)


###
  params:
    dbFn: a db function as used elsewhere in our app, specifying the table on which to upsert
    idObj: an object with key/value pairs that uniquely identify the row to be updated/inserted (the keys of this
        object are used to create the conflict clause of the upsert)
    entityObj: an object with key/value pairs that specify the column values to be updated/inserted (this can contain
        the same key/value pairs as idObj plus the update pairs, or just the update pairs themselves)
    conflictOverrideObj: an object with override key/value pairs that should be used for update when insert isn't
        possible; note knex.raw() clauses are allowed as values here, and giving a value of `undefined` will exclude
        that column from being set on update
    transaction: the transaction to use for the upsert
###
upsert = ({dbFn, idObj, entityObj, conflictOverrideObj, transaction}) ->
  upsertBindings = buildUpsertBindings({idObj, entityObj, conflictOverrideObj, tableName: dbFn.tableName})
  dbFn({transaction}).raw(upsertBindings.sql, upsertBindings.bindings)


# http://stackoverflow.com/questions/20582500/how-to-check-if-a-table-exists-in-a-given-schema
# Note that querying pg_class is faster than querying information_schema.tables
checkTableExists = (dbFn) ->
  dbs.get(dbFn.dbName)
  .select(1)
  .from('pg_catalog.pg_class')
  .where
    relname: dbFn.tableName
    relkind: 'r'
  .then (check=[]) ->
    return check.length > 0


module.exports = {
  between
  ageOrDaysFromStartToNow
  orderByDistanceFromPoint
  allPatternsInAnyColumn
  select
  singleRow
  expectSingleRow
  whereIn
  orWhereIn
  whereNotIn
  orWhereNotIn
  whereAndWhereIn
  orWhereAndWhereIn
  whereInBounds
  getClauseString
  safeJsonArray
  safeJsonEntity
  isUnique
  columns
  whereIntersects
  sqlizeColName
  buildRawBindings
  buildQuery
  buildUpsertBindings
  upsert
  checkTableExists
}
