logger = require('../config/logger').spawn('map:filterSummary:drawnShapes')
filterSummaryService = require './service.properties.combined.filterSummary'
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

detailsName = tables.finalized.combined.tableName
drawnShapesName = tables.user.drawnShapes.tableName

throwOnUndefined = (thing, name) ->
  unless thing
    throw new Error("#{name} is undefined")

throwOnUndefined(detailsName,"detailsName")
throwOnUndefined(drawnShapesName,"drawnShapesName")

getDefaultQuery = (query = filterSummaryService.getDefaultQuery()) ->
  #http://stackoverflow.com/questions/12204834/get-distance-in-meters-instead-of-degrees-in-spatialite
  #earth meters per degree 111195
  query.joinRaw tables.finalized.combined().raw """
    inner join #{drawnShapesName} on ST_Within(#{detailsName}.geometry_raw, #{drawnShapesName}.geom_polys_raw)
     or
     ST_DWithin(
     #{detailsName}.geometry_raw,
     #{drawnShapesName}.geom_point_raw,
     text(#{drawnShapesName}.shape_extras->'radius')::float/#{distance.METERS_PER_EARTH_RADIUS})
    """

getFilterSummaryAsQuery = ({queryParams, limit, query, permissions}) ->
  query ?= getDefaultQuery()
  # logger.debug.green queryParams, true
  query = filterSummaryService.getFilterSummaryAsQuery({queryParams, limit, query})
  .where("#{drawnShapesName}.project_id", queryParams.project_id)

  if queryParams.isArea?
    if queryParams.isArea
      query = query.whereNotNull("#{drawnShapesName}.area_name", queryParams.project_id)

  query

getResultCount = ({queryParams}) ->
  query = getDefaultQuery(sqlHelpers.selectCountDistinct(tables.finalized.combined()))
  q = getFilterSummaryAsQuery({queryParams, query})
  logger.debug q.toString()
  q

module.exports = {
  getResultCount
  getFilterSummaryAsQuery
  transforms: _.merge {}, filterSummaryService.transforms,
    isArea: validators.boolean(truthy: true, falsy: false)
    bounds: validators.string(null:true)
    project_id: validators.integer()#even though this is set on the backend it is needed so it is not lost in base impl
}
