tables = require '../config/tables'
logger = require('../config/logger').spawn('service:project')
frontendRoutes = require '../../common/config/routes.frontend'
{profile, notes} = require './services.user'
{ThenableCrud, thenableHasManyCrud} = require '../utils/crud/util.crud.service.helpers'
{basicColumns, joinColumns, joinColumnNames} = require '../utils/util.sql.columns'
sqlHelpers = require '../utils/util.sql.helpers'
DrawnShapesCrud = require './service.drawnShapes'
dbs = require '../config/dbs'
userSvc = (require '../services/services.user').user.clone().init(false, true, 'singleRaw')
permissionsService = require './service.permissions'
profileSvc = require './service.profiles'
keystoreSvc = require '../services/service.keystore'
uuid = require '../utils/util.uuid'

Promise = require 'bluebird'
_ = require 'lodash'

safeProject = basicColumns.project
safeProfile = basicColumns.profile
safeNotes = basicColumns.notes
safeUser = sqlHelpers.columns.user
vero = null
require('../services/email/vero').then (svc) -> vero = svc.vero


_inviteClient = (clientEntryValue) ->
  # save important information for client login later in keystore
  # `clientEntryValue` also has data for vero template, so we send it there too
  clientEntryKey = uuid.genUUID()

  if clientEntryValue.evtdata.name == 'client_created'
    # url for a password creation input for client
    verify_url = "http://#{clientEntryValue.evtdata.verify_host}/#{frontendRoutes.clientEntry.replace(':key', clientEntryKey)}"
  else
    # url to the project dashboard (client will need to login if not logged)
    verify_url = "http://#{clientEntryValue.evtdata.verify_host}/project/#{clientEntryValue.project.id}"

  clientEntryValue.evtdata.verify_url = verify_url
  logger.debug -> "_inviteClient(), clientEntryValue:\n#{JSON.stringify(clientEntryValue)}"
  keystoreSvc.setValue(clientEntryKey, clientEntryValue, namespace: 'client-entry')
  .then () ->
    # email new client
    vero.createUserAndTrackEvent(
      clientEntryValue.user.id
      clientEntryValue.user.email
      clientEntryValue.user
      clientEntryValue.evtdata.name
      clientEntryValue
    )
    # TODO - add to notification job queue upon possible failure,
    #   then possibly move to `services/email/vero` if it gets squirrely enough

class ProjectCrud extends ThenableCrud
  constructor: () ->
    super(arguments...)

  # profilesFact: (dbFn = tables.user.project, joinCrud = profile) ->
  #   logger.debug dbFn.tableName
  #   thenableHasManyCrud dbFn, joinColumns.profile, joinCrud,
  #     "#{tables.user.profile.tableName}.project_id",
  #     "#{tables.user.project.tableName}.id",
  #     "#{tables.user.profile.tableName}.id"

  clientsFact: (dbFn = tables.auth.user, joinCrud = profile) ->
    logger.debug dbFn.tableName
    thenableHasManyCrud dbFn, joinColumns.client, joinCrud,
      "#{tables.user.profile.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id",
      "#{tables.user.profile.tableName}.id"

  notesFact: (dbFn = tables.user.project, joinCrud = notes) ->
    logger.debug dbFn.tableName
    thenableHasManyCrud dbFn, joinColumns.notes, joinCrud,
      "#{tables.user.notes.tableName}.project_id",
      "#{tables.user.project.tableName}.id",
      "#{tables.user.notes.tableName}.id"

  drawnShapesFact: (dbFn = tables.user.drawnShapes) ->
    logger.debug dbFn.tableName
    new DrawnShapesCrud(dbFn)

  init: () =>
    @clients = @clientsFact().init(arguments...)
    # @clients.doLogQuery = true
    #(dbFn, @rootCols, @joinCrud, @origJoinIdStr, @origRootIdStr, idKey) ->
    @notes = @notesFact().init(arguments...)
    @notes.doLogQuery = true

    @drawnShapes = @drawnShapesFact()
    # @drawnShapes.doLogQuery = true

    # @profiles = @profilesFact().init(arguments...)

    super(arguments...)

  #(id, doLogQuery = false, entity, safe, fnExec = execQ) ->
  delete: (idObj, doLogQuery, entity, safe = safeProject, fnExec) ->
    console.log "service.user.project.coffee delete()"
    profileSvc.getAll project_id: idObj.id, "#{tables.user.profile.tableName}.auth_user_id": idObj.auth_user_id, doLogQuery
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

        # Reset the sandbox (profile and project fields)
        #promises.push profileSvc.update profile.id, reset, safeProfile, doLogQuery
        promises.push profileSvc.update(_merge(reset, id: profile.id), idObj.auth_user_id)

        # profile.id, reset, safeProfile, doLogQuery

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

  addClient: (clientEntryValue) ->
    {user, parent, project, evtdata} = clientEntryValue
    dbs.transaction 'main', (trx) ->
      # get the invited user if exists
      tables.auth.user(transaction: trx)
      .select 'id', 'email', 'first_name', 'last_name', 'parent_id', 'username'
      .where email: user.email
      .then (result) ->

        # create new user for 'client_created' vero event
        if result.length == 0
          userPromise = tables.auth.user(transaction: trx)
          .insert user
          .returning 'id'
          .then ([id]) ->
            user.id = id
            evtdata.name = 'client_created'

        # use existing user for 'client_invited' vero event
        else
          user = _.merge user, result[0]
          evtdata.name = 'client_invited'
          userPromise = Promise.resolve()

        userPromise

        # invite the client (whether created or existing)
        .then () ->
          _inviteClient clientEntryValue

        # permission stuff
        .then ->
          # TODO - TEMPORARY WORKAROUND - Look up permission ID from DB
          permissionsService.getPermissionForCodename 'unlimited_logins'
        .then (authPermission) ->
          logger.debug "Found new client permission id: #{authPermission.id}"
          # TODO - TEMPORARY WORKAROUND to add unlimited access permission to client user, until onboarding is completed
          throw new Error 'Could not find permission id for "unlimited_logins"' unless authPermission
          permission =
            user_id: user.id
            permission_id: authPermission.id
            transaction: trx
          permissionsService.setPermissionForUserId permission


        # profile stuff
        .then ->
          newProfile =
            auth_user_id: user.id
            parent_auth_user_id: user.parent_id
            project_id: project.id
          profileSvc.createForProject newProfile, trx

#temporary to not conflict with project
module.exports = ProjectCrud
