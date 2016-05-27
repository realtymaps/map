logger = require '../config/logger'
BaseFilterSummaryService = require './service.properties.base.filterSummary'
_ = require 'lodash'
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

detailsName = tables.property.propertyDetails.tableName
drawnShapesName = tables.user.drawnShapes.tableName

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

getFilterSummaryAsQuery = (filters, limit, query = getDefaultQuery()) ->
  # logger.debug.green filters, true
  query = BaseFilterSummaryService.getFilterSummaryAsQuery(filters, limit, query)
  .where("#{drawnShapesName}.project_id", filters.project_id)

  if filters.isArea?
    if filters.isArea
      query = query.whereNotNull("#{drawnShapesName}.neighbourhood_name", filters.project_id)

  query

getResultCount = (filters) ->
  query = getDefaultQuery(sqlHelpers.selectCountDistinct(tables.property.propertyDetails()))
  q = getFilterSummaryAsQuery(filters,null, query)
  logger.debug q.toString()
  q

module.exports =
  getDefaultQuery: getDefaultQuery
  getResultCount: getResultCount
  getFilterSummaryAsQuery: getFilterSummaryAsQuery
  transforms: _.merge {}, BaseFilterSummaryService.transforms,
    isArea: validators.boolean(truthy: true, falsy: false)
    bounds: validators.string(null:true)
    project_id: validators.integer()#even though this is set on the backend it is needed so it is not lost in base impl
