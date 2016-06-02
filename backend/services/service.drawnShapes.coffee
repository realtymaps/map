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
      .then (rows) ->
        toGeoFeatureCollection rows,
          toMove: @drawnShapeCols
          geometry: ['geom_point_json', 'geom_polys_json', 'geom_line_json']
          deletes: ['rm_inserted_time', 'rm_modified_time',
            'geom_point_raw', 'geom_polys_raw', 'geom_line_raw']

    getAllBase: (query, options = {}, nullClause = 'whereNull') ->
      options.returnKnex = true
      @toGeoJson(ReturningServiceEzCrud::getAll.call(@, query, options)
        .knex[nullClause]('area_name'))

    getAll: (query, options) ->
      @getAllBase query, options

    areas: (query, options) ->
      @getAllBase query, options, 'whereNotNull'
