logger = require '../config/logger'
BaseFilterSummaryService = require './service.properties.base.filterSummary'
_ = require 'lodash'
tablesNames = require '../config/tableNames'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
{validators} = require '../utils/util.validation'

###
override:
- getFilterSummaryAsQuery
- getResultCount
- getDefaultQuery
- (optionally) validateAndTransform
- tested non knex query that works

select distinct on (rm_property_id) *
from mv_property_details
inner join user_drawn_shapes on
st_within(mv_property_details.geom_point_raw,user_drawn_shapes.geom_polys_raw) or
(
user_drawn_shapes.geom_point_raw is not null and
user_drawn_shapes.shape_extras is not null and
ST_DWithin(
mv_property_details.geom_point_raw,
user_drawn_shapes.geom_point_raw,
text(user_drawn_shapes.shape_extras->'radius')::float)
) limit 500;

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
     text(#{drawnShapesName}.shape_extras->'radius')::float/111195)
    """

getFilterSummaryAsQuery = (state, filters, limit, query = getDefaultQuery()) ->
  # logger.debug.green state, true
  # logger.debug.green filters.current_project_id, true
  BaseFilterSummaryService.getFilterSummaryAsQuery(state, filters, limit, query)
  .where("#{drawnShapesName}.project_id", filters.current_project_id)

getResultCount = (state, filters) ->
  query = getDefaultQuery(sqlHelpers.selectCountDistinct(tables.property.propertyDetails()))
  q = getFilterSummaryAsQuery(state, filters,null, query)
  logger.debug q.toString()
  q

module.exports =
  getDefaultQuery: getDefaultQuery
  getResultCount: getResultCount
  getFilterSummaryAsQuery: getFilterSummaryAsQuery
  transforms: _.extend {}, BaseFilterSummaryService.transforms,
    bounds: validators.string(null:true)
    current_project_id:
      transforms: [validators.integer()]
      required: true
