logger = require '../config/logger'
BaseFilterSummaryService = require './service.properties.base.filterSummary'
_ = require 'lodash'
tablesNames = require '../config/tableNames'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
{validators} = require '../utils/util.validation'
{distance} = require '../../common/utils/enums/util.enums.map.coord_system.coffee'

###
override:
- getFilterSummaryAsQuery
- getResultCount
- getDefaultQuery
- (optionally) validateAndTransform
- tested non knex query that works
###

detailsName = tablesNames.property.propertyDetails
drawnShapesName = tablesNames.user.drawnShapes

throwOnUndefined = (thing, name) ->
  unless thing
    throw new Error("#{name} is undefined")

throwOnUndefined(detailsName,"detailsName")
throwOnUndefined(drawnShapesName,"drawnShapesName")

getDefaultQuery = (query = BaseFilterSummaryService.getDefaultQuery()) ->
  #http://stackoverflow.com/questions/12204834/get-distance-in-meters-instead-of-degrees-in-spatialite
  #earth meters per degree 111195
  query.joinRaw tables.property.propertyDetails().raw """
    inner join #{drawnShapesName} on ST_Within(#{detailsName}.geom_point_raw, #{drawnShapesName}.geom_polys_raw)
     or
     ST_DWithin(
     #{detailsName}.geom_point_raw,
     #{drawnShapesName}.geom_point_raw,
     text(#{drawnShapesName}.shape_extras->'radius')::float/#{distance.METERS_PER_EARTH_RADIUS})
    """

getFilterSummaryAsQuery = (state, filters, limit, query = getDefaultQuery()) ->
  # logger.debug.green state, true
  logger.debug.green filters, true
  query = BaseFilterSummaryService.getFilterSummaryAsQuery(state, filters, limit, query)
  .where("#{drawnShapesName}.project_id", filters.current_project_id)

  if filters.isNeighbourhood?
    if filters.isNeighbourhood
      query = query.whereNotNull("#{drawnShapesName}.neighbourhood_name", filters.current_project_id)
    else
      query = query.whereNull("#{drawnShapesName}.neighbourhood_name", filters.current_project_id)

  logger.debug.cyan query.toString()
  query

getResultCount = (state, filters) ->
  query = getDefaultQuery(sqlHelpers.selectCountDistinct(tables.property.propertyDetails()))
  q = getFilterSummaryAsQuery(state, filters,null, query)
  logger.debug q.toString()
  q

module.exports =
  getDefaultQuery: getDefaultQuery
  getResultCount: getResultCount
  getFilterSummaryAsQuery: getFilterSummaryAsQuery
  transforms: _.merge {}, BaseFilterSummaryService.transforms,
    isNeighbourhood: validators.boolean()
    bounds: validators.string(null:true)
    current_project_id:
      transforms: [validators.integer()]
      required: true
