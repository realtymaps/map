ReturningServiceEzCrud = require '../utils/crud/util.ezcrud.service.returning'
{toGeoFeatureCollection} = require '../../common/utils/util.geomToGeoJson'
{basicColumns} = require '../utils/util.sql.columns'

module.exports =
  class DrawnShapesServiceCrud extends ReturningServiceEzCrud
    constructor: () ->
      super(arguments...)
      @drawnShapeCols = basicColumns.drawnShapes

    toGeoJson: (query) ->
      query
      .then (rows) =>
        toGeoFeatureCollection {
          rows
          opts:
            toMove: @drawnShapeCols
            geometry: ['geometry_center', 'geometry', 'geometry_line']
            deletes: ['rm_inserted_time', 'rm_modified_time',
              'geometry_center_raw', 'geometry_raw', 'geometry_line_raw']
        }

    getAllBase: (query, options = {}, nullClause = 'whereNull') ->
      options.returnKnex = true
      @toGeoJson(ReturningServiceEzCrud::getAll.call(@, query, options)
        .knex[nullClause]('area_name'))

    getAll: (query, options) ->
      @getAllBase query, options

    areas: (query, options) ->
      @getAllBase query, options, 'whereNotNull'

    getById: (query, options = {}, nullClause = 'whereNotNull') ->
      options.returnKnex = true
      @toGeoJson(ReturningServiceEzCrud::getById.call(@, query, options)
        .knex[nullClause]('area_name'))
