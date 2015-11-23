logger = require '../config/logger'
tables = require '../config/tables'
{profile, notes, project, drawnShapes} = require './services.user'
{crud, ThenableCrud, thenableHasManyCrud, ThenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'
{joinColumns, joinColumnNames} = require '../utils/util.sql.columns'
sqlHelpers = require '../utils/util.sql.helpers'
{toGeoFeatureCollection} = require '../utils/util.geomToGeoJson'

safeProject = sqlHelpers.columns.project
safeProfile = sqlHelpers.columns.profile
safeUser = sqlHelpers.columns.user
safeNotes = sqlHelpers.columns.notes


clientIdCol = joinColumns.client[0]
projectId = "#{tables.user.project.tableName}.id"

class DrawnShapesCrud extends ThenableHasManyCrud
  constructor: () ->
    super(arguments...)
    @drawnShapeCols = sqlHelpers.columns.drawnShapes

  updateManyShapes: (entity, unique, doUpdate, safe) ->
    for feature in entity.featureCollection
      do (feature) =>
        @base.upsert feature, unique, doUpdate, safe

  upsert: (entity, unique, doUpdate, safe) ->
    updateManyShapes(entity, unique, doUpdate, safe)

  getAll: () ->
    super(arguments...)
    .then toGeoFeatureCollection(@drawnShapeCols)


class ProjectCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)
  init: () =>
    @clients = thenableHasManyCrud(tables.auth.user, joinColumns.client, profile,
      joinColumnNames.client.auth_user_id, undefined, clientIdCol).init(arguments...)
    # @clients.doLogQuery = true
    #(dbFn, @rootCols, @joinCrud, @origJoinIdStr, @origRootIdStr, idKey) ->
    @notes = thenableHasManyCrud(tables.user.notes, joinColumns.notes, project,
      projectId, "#{tables.user.notes.tableName}.project_id",
      "#{tables.user.notes.tableName}.id").init(arguments...)
    @notes.doLogQuery = true

    @drawnShapes = new DrawnShapesCrud(tables.user.drawnShapes, joinColumns.drawnShapes, project,
      projectId, "#{tables.user.drawnShapes.tableName}.project_id").init(arguments...)
    # @drawnShapes.doLogQuery = true
    super(arguments...)

  #(id, doLogQuery = false, entity, safe, fnExec = execQ) ->
  delete: (idObj, doLogQuery, entity, safe = safeProject, fnExec) ->
    @getById idObj, doLogQuery, entity, safe
    .then (projects) =>
      project = projects[0]
      throw new Error 'Project not found' unless project?

      # If this is the users's sandbox -- just reset to default/empty state and remove associated notes
      if project.sandbox is true
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
        @clients.delete {}, @doLogQuery, project_id: project.id, auth_user_id: idObj.user.id, safeProfile
        .then () =>
          @notes.delete {}, @doLogQuery, project_id: project.id, auth_user_id: idObj.user.id, safeNotes
        .then () =>
          super idObj, doLogQuery, entity, safe, fnExec


#temporary to not conflict with project
module.exports = new ProjectCrud(tables.user.project).init(false)
