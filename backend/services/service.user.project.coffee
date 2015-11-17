logger = require '../config/logger'
tables = require '../config/tables'
{profile, notes, project, drawnShapes} = require './services.user'
{crud, ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'
{joinColumns} = require '../utils/util.sql.columns'

clientIdCol = joinColumns.client[0]
projectId = "#{tables.user.project.tableName}.id"

class ProjectCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)
  init: () =>
    @clients = thenableHasManyCrud(tables.auth.user, joinColumns.client, profile,
      'project_id', undefined, clientIdCol).init(arguments...)
    # @clients.doLogQuery = true
    #(dbFn, @rootCols, @joinCrud, @origJoinIdStr, @origRootIdStr, idKey) ->
    @notes = thenableHasManyCrud(tables.user.notes, joinColumns.notes, project,
      projectId, "#{tables.user.notes.tableName}.project_id",
      "#{tables.user.notes.tableName}.id").init(arguments...)
    @notes.doLogQuery = true

    @drawnShapes = thenableHasManyCrud(tables.user.drawnShapes, joinColumns.drawnShapes, project,
      projectId, "#{tables.user.drawnShapes.tableName}.project_id").init(arguments...)
    # @drawnShapes.doLogQuery = true
    super(arguments...)

#temporary to not conflict with project
module.exports = new ProjectCrud(tables.user.project).init(false)
