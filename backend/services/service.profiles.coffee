Promise = require 'bluebird'
_ = require 'lodash'
logger = require '../config/logger'
tables = require '../config/tables'
db = require('../config/dbs').get('main')
{singleRow} = require '../utils/util.sql.helpers'
{basicColumns, joinColumns} = require '../utils/util.sql.columns'
{currentProfile} = require '../../common/utils/util.profile'
userProfileSvc = (require './services.user').user.profiles
projectSvc = (require './services.user').project

safeProject = basicColumns.project
safeProfile = basicColumns.profile

create = (newProfile) ->
  Promise.try () ->
    tables.user.project()
    .returning('id')
    .insert(_.pick newProfile, safeProject)
  .then singleRow
  .then (project) ->
    newProfile.project_id = project
    tables.user.profile()
    .returning(safeProfile)
    .insert(_.pick newProfile, safeProfile)
  .then (inserted) ->
    inserted?[0]

# if we already know project, we can use this routine
createForProject = (newProfile, transaction = null) ->
  if !newProfile.project_id? then throw new Error '`project_id` is required to create profile.'
  tables.user.profile(transaction: transaction)
  .returning safeProfile
  .insert(_.pick newProfile, safeProfile)

# returns the main query for profile & project list query
# `where` can honor a test on any field in `auth_user`, `user_project`, `user_profile`
_getProfileWhere = (where = {}) ->
  tables.user.profile()
  .select(joinColumns.profile)
  .select(
    db.raw("auth_user.first_name || ' ' || auth_user.last_name as parent_name")
  )
  .where(where)
  .join(tables.user.project.tableName, () ->
    this.on("#{tables.user.profile.tableName}.project_id", "#{tables.user.project.tableName}.id")
  )
  .leftOuterJoin(tables.auth.user.tableName, () ->
    this.on("#{tables.auth.user.tableName}.id", "#{tables.user.profile.tableName}.parent_auth_user_id")
  )

# internal profile update
_updateProfileWhere = (profile, where) ->
  safeUpdate = _.pick(profile, safeProfile)
  q = tables.user.profile()
  .update(safeUpdate)
  .where(where)
  q

# general purpose getAll endpoint for profile model (no project fields)
getAll = (entity) ->
  tables.user.profile()
  .select(safeProfile)
  .where(entity)

# this gives us profiles for a subscribing user, getting and/or creation a sandbox if applicable
# Note: this differs from a usual "getAll" endpoint in that we bundle some project fields with profile results
getProfiles = (auth_user_id) -> Promise.try () ->
  _getProfileWhere
    "#{tables.user.profile.tableName}.auth_user_id": auth_user_id
  .then (profiles) ->
    sandbox = _.find profiles, (p) -> p.sandbox is true
    if sandbox?
      profiles
    else
      logger.debug "No sandbox exists for auth_user_id: #{auth_user_id}. Creating..."
      create auth_user_id: auth_user_id, sandbox: true, can_edit: true
      .then () ->
        # re-fetch for full list w/ ids
        _getProfileWhere
          "#{tables.user.profile.tableName}.auth_user_id": auth_user_id

  .then (profiles) ->
    _.indexBy profiles, 'id'

# this gives us profiles for a non-subscribing (client) user, forego dealing with sandbox
getClientProfiles = (auth_user_id) -> Promise.try () ->
  _getProfileWhere
    "#{tables.user.profile.tableName}.auth_user_id": auth_user_id
    "#{tables.user.project.tableName}.sandbox": false
  .then (profiles) ->
    _.indexBy profiles, 'id'

getCurrentSessionProfile = (session) ->
  currentProfile(session)

# The parameter "profile" may actually be an entity with both project & profile fields, but doesn't have to be
update = (profile, auth_user_id) ->
  console.log "profile update(), profile:\n#{JSON.stringify(profile,null,2)}\n\n"
  Promise.throw("auth_user_id is undefined") unless auth_user_id
  updatePromises = []

  # update the project model `properties_selected` portion of the profileProject data
  if !_.isEmpty(toUpdate = _.pick(profile, ['properties_selected']))
    updatePromises.push projectSvc.update(profile.project_id, toUpdate)

  # update the profile model portion of the profileProject data
  where = {id: profile.id, auth_user_id: auth_user_id}
  updatePromises.push _updateProfileWhere(profile, where)

  Promise.all(updatePromises)
  .catch (err) ->
    logger.error "error while updating profile id #{profile.id}: #{err}"
    Promise.reject(err)

_hasProfileStateChanged = (profile, partialState) ->
  #avoid unnecessary saves as there is the possibility for race conditions
  needsSave = false
  for key,part of partialState
    if !_.isEqual part, profile[key]
      needsSave = true
      break
  needsSave

updateCurrent = (session, partialState, safe) ->
  console.log "profile updateCurrent()"
  sessionProfile = getCurrentSessionProfile(session)
  saveSessionPromise = null
#  logger.debug "service.user needsSave: #{needsSave}"
  if _hasProfileStateChanged(sessionProfile, partialState)
    _.extend(sessionProfile, partialState)
    saveSessionPromise = session.saveAsync() #save immediately to prevent problems from overlapping AJAX calls
  else
    saveSessionPromise = Promise.resolve()

  saveSessionPromise.then () ->
    update(sessionProfile, session.userid, safe)

module.exports =
  getAll: getAll
  getProfiles: getProfiles
  getClientProfiles: getClientProfiles
  getCurrentSessionProfile: getCurrentSessionProfile
  updateCurrent: updateCurrent
  update: update
  create: create
  createForProject: createForProject
