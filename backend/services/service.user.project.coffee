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
  delete: (idObj, doLogQuery, entity, safe = safeProject, fnExec) ->
    @profiles.getAll project_id: idObj.id, "#{tables.user.profile.tableName}.auth_user_id": idObj.auth_user_id, doLogQuery
    .then sqlHelpers.singleRow
    .then (profile) =>
      throw new Error 'Project not found' unless profile?

      toRemove =
        auth_user_id: idObj.auth_user_id
        project_id: profile.project_id

      promises = []

      # Remove notes in all cases
      promises.push @notes.delete {}, doLogQuery, toRemove

      # Remove shapes in all cases
      promises.push @drawnShapes.delete {}, doLogQuery, toRemove

      if profile.sandbox is true

        reset =
          filters: {}
          map_results: {}
          map_position: {}
          properties_selected: {}

        # Reset the sandbox (project fields)
        promises.push @update profile.project_id, reset, safeProject, doLogQuery

        # Reset the sandbox (profile fields)
        promises.push @profiles.update profile.id, reset, safeProfile, doLogQuery

      else
        # Delete client profiles (not the users themselves)
        promises.push @clients.delete {}, doLogQuery,
          project_id: profile.project_id,
          parent_auth_user_id: idObj.auth_user_id

        # Delete the project itself
        promises.push super id: profile.project_id, doLogQuery

      Promise.all promises
      .then () ->
        true

#temporary to not conflict with project
module.exports = ProjectCrud
