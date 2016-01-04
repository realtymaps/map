_ = require 'lodash'
tables = require '../config/tables'
logger = require '../config/logger'
{profile, notes} = require './services.user'
{ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'
{joinColumns, joinColumnNames} = require '../utils/util.sql.columns'
sqlHelpers = require '../utils/util.sql.helpers'
{toGeoFeatureCollection} = require '../utils/util.geomToGeoJson'
Promise = require 'bluebird'

safeProject = sqlHelpers.columns.project
safeProfile = sqlHelpers.columns.profile
safeNotes = sqlHelpers.columns.notes


class DrawnShapesCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)
    @drawnShapeCols = sqlHelpers.columns.drawnShapes

  init:() =>
    super arguments...
    @doWrapSingleThen = 'singleRaw'
    @

  getAll: () ->
    super(arguments...)
    .then toGeoFeatureCollection
      toMove: @drawnShapeCols
      geometry: ['geom_point_json', 'geom_polys_json', 'geom_line_json']
      deletes: ['rm_inserted_time', 'rm_modified_time', 'geom_point_raw', 'geom_polys_raw', 'geom_line_raw']

class ProjectCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  profilesFact: (dbFn = tables.user.project, joinCrud = profile) ->
    # logger.debug.cyan dbFn
    # logger.debug.cyan joinCrud
    thenableHasManyCrud dbFn, joinColumns.profile, joinCrud,
      "#{tables.user.profile.tableName}.project_id",
      "#{tables.user.project.tableName}.id",
      "#{tables.user.profile.tableName}.id"

  clientsFact: (dbFn = tables.auth.user, joinCrud = profile) ->
    # logger.debug.cyan dbFn
    # logger.debug.cyan joinCrud
    thenableHasManyCrud dbFn, joinColumns.client, joinCrud,
      "#{tables.user.profile.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id",
      "#{tables.user.profile.tableName}.id"

  notesFact: (dbFn = tables.user.project, joinCrud = notes) ->
    # logger.debug.cyan dbFn
    # logger.debug.cyan joinCrud
    thenableHasManyCrud dbFn, joinColumns.notes, joinCrud,
      "#{tables.user.notes.tableName}.project_id",
      "#{tables.user.project.tableName}.id",
      "#{tables.user.notes.tableName}.id"

  drawnShapesFact: (dbFn = tables.user.drawnShapes) ->
    # logger.debug.cyan dbFn
    new DrawnShapesCrud(dbFn)

  init: () =>
    @clients = @clientsFact().init(arguments...)
    # @clients.doLogQuery = true
    #(dbFn, @rootCols, @joinCrud, @origJoinIdStr, @origRootIdStr, idKey) ->
    @notes = @notesFact().init(arguments...)
    @notes.doLogQuery = true

    @drawnShapes = @drawnShapesFact().init(arguments...)
    # @drawnShapes.doLogQuery = true

    @profiles = @profilesFact().init(arguments...)

    super(arguments...)

  #(id, doLogQuery = false, entity, safe, fnExec = execQ) ->
  delete: (idObj, doLogQuery = true, entity, safe = safeProject, fnExec) ->
    @getById idObj, doLogQuery, entity, safe
    .then (project) =>
      throw new Error 'Project not found' unless project?

      toRemove = auth_user_id: idObj.auth_user_id, project_id: project.id

      promises = [
        @notes.delete {}, doLogQuery, toRemove
      ]

      # If this is the users's sandbox -- just reset to default/empty state and remove associated notes
      if project.sandbox is true
        promises.push @update project.id, properties_selected: {}, safeProject, doLogQuery

        promises.push(
          @clients.getAll project_id: project.id, auth_user_id: project.auth_user_id
          .then (profiles) =>
            profileReset =
              filters: {}
              map_results: {}
              map_position: {}
            @clients.update profiles[0].id, profileReset, safeProfile, doLogQuery
        )

      else
        promises.push super idObj, doLogQuery
        promises.push @clients.delete {}, doLogQuery, toRemove

      Promise.all promises
      .then () ->
        project.sandbox


#temporary to not conflict with project
module.exports = ProjectCrud
