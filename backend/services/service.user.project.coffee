_ = require 'lodash'
tables = require '../config/tables'
logger = require '../config/logger'
{profile, project} = require './services.user'
{ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'
{joinColumns, joinColumnNames} = require '../utils/util.sql.columns'
sqlHelpers = require '../utils/util.sql.helpers'
{toGeoFeatureCollection} = require '../utils/util.geomToGeoJson'
FilterSummaryBus = require './service.properties.filterSummary'
DrawnShapesFiltSvc = require './service.properties.drawnShapes.filterSummary'

safeProject = sqlHelpers.columns.project
safeProfile = sqlHelpers.columns.profile
safeNotes = sqlHelpers.columns.notes

clientIdCol = joinColumns.client[0]
projectId = "#{tables.user.project.tableName}.id"

class DrawnShapesCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)
    @drawnShapeCols = sqlHelpers.columns.drawnShapes

  getAll: () ->
    super(arguments...)
    .then toGeoFeatureCollection
      toMove: @drawnShapeCols
      geometry: ['geom_point_json', 'geom_polys_json', 'geom_line_json']
      deletes: ['rm_inserted_time', 'rm_modified_time', 'geom_point_raw', 'geom_polys_raw', 'geom_line_raw']

  #TODO: filters in filterSummary should be handled at the route level
  getPropertiesWithin: (projectId, state, rawFilters) ->
    FilterSummaryBus.getFilterSummary(state, rawFilters, undefined, DrawnShapesFiltSvc)
    .where("#{@svc.tableName}.project_id", projectId)

class ProjectCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  clientsFact: (dbFn = tables.auth.user, joinCrud = profile) ->
    # logger.debug.cyan dbFn
    # logger.debug.cyan joinCrud
    thenableHasManyCrud(dbFn, joinColumns.client, joinCrud, joinColumnNames.client.auth_user_id, undefined, clientIdCol)

  notesFact: (dbFn = tables.user.notes, joinCrud = project) ->
    # logger.debug.cyan dbFn
    # logger.debug.cyan joinCrud
    thenableHasManyCrud(dbFn, joinColumns.notes, joinCrud,
      projectId, "#{tables.user.notes.tableName}.project_id",
      "#{tables.user.notes.tableName}.id")

  drawnShapesFact: (dbFn = tables.user.drawnShapes) ->
    logger.debug.cyan dbFn
    new DrawnShapesCrud(dbFn)

  init: () =>
    @clients = @clientsFact().init(arguments...)
    # @clients.doLogQuery = true
    #(dbFn, @rootCols, @joinCrud, @origJoinIdStr, @origRootIdStr, idKey) ->
    @notes = @notesFact().init(arguments...)
    @notes.doLogQuery = true

    @drawnShapes = @drawnShapesFact().init(arguments...)
    # @drawnShapes.doLogQuery = true
    super(arguments...)

  #(id, doLogQuery = false, entity, safe, fnExec = execQ) ->
  delete: (idObj, doLogQuery, entity, safe = safeProject, fnExec) ->
    @getById idObj, doLogQuery, entity, safe
    .then sqlHelpers.singleRow
    .then (project) ->
      throw new Error 'Project not found' unless project?

      # If this is the users's sandbox -- just reset to default/empty state and remove associated notes
      if project.sandbox is true
        logger.debug.yellow 'is sandbox'
        @update project.id, properties_selected: {}, safeProject, doLogQuery
        .then () =>
          @clients.getAll idObj
        .then (profiles) =>
          profileReset =
            filters: {}
            map_results: {}
            map_position: {}

          @clients.update profiles[0].id, profileReset, safeProfile, @doLogQuery

        .then () =>
          @notes.delete {}, doLogQuery, project_id: project.id, auth_user_id: idObj.auth_user_id, safeNotes
      else
        logger.debug.yellow 'not sandbox'
        @clients.delete {}, @doLogQuery,
          logger.debug.yellow 'not sandbox clients delete'
          _.set(auth_user_id: idObj.auth_user_id, joinColumnNames.profile.project_id, project.id), safeProfile
        .then () =>
          @notes.delete {}, @doLogQuery,
            logger.debug.yellow 'not sandbox notes delete'
            _.set(auth_user_id: idObj.auth_user_id, joinColumnNames.notes.project_id, project.id), safeNotes
        .then () =>
          logger.debug.yellow 'not sandbox project delete'
          super idObj, doLogQuery, entity, safe, fnExec


#temporary to not conflict with project
module.exports = ProjectCrud
