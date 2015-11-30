BaseFilterSummaryService = require './service.properties.base.filterSummary'
_ = require 'lodash'
tablesNames = require '../config/tableNames'
sqlHelpers = require '../utils/util.sql.helpers'

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
drawnShapesName = tablesNames.user.drawn_shapes
getDefaultQuery = () ->
  BaseFilterSummaryService.getDefaultQuery()
  .innerJoin drawnShapesName, ->
    @on "ST_Within(#{detailsName}.geom_point_raw, #{drawnShapesName}.geom_polys_raw)"
    @orOn """
    #{drawnShapesName}.geom_point_raw is not null and
    #{drawnShapesName}.shape_extras is not null and
    ST_DWithin(
    #{detailsName}.geom_point_raw,
    #{drawnShapesName}.geom_point_raw,
    text(#{drawnShapesName}.shape_extras->'radius')::float)
    """

getFilterSummaryAsQuery = (state, filters, limit, query = getDefaultQuery()) ->
  BaseFilterSummaryService.getFilterSummaryAsQuery(state, filters, limit, query)

getResultCount = (state, filters) ->
  getFilterSummaryAsQuery(state, filters,
    null, sqlHelpers.selectCountDistinct(detailsName))

getDefaultQuery: getDefaultQuery
getResultCount: getResultCount
getFilterSummaryAsQuery: getFilterSummaryAsQuery
