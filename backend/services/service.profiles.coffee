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
  .join("#{tables.user.project.tableName}", () ->
    this.on("#{tables.user.profile.tableName}.project_id", "#{tables.user.project.tableName}.id")
  )
  .leftOuterJoin("#{tables.auth.user.tableName}", () ->
    this.on("#{tables.auth.user.tableName}.id", "#{tables.user.profile.tableName}.parent_auth_user_id")
  )

# this gives us profiles for a subscribing user, getting and/or creation a sandbox if applicable
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
        userProfileSvc.getAll "#{tables.user.profile.tableName}.auth_user_id": auth_user_id
  .then (profiles) ->
    _.indexBy profiles, 'id'

# this gives us profiles for a non-subscribing (client) user, forego dealing with sandbox
getClientProfiles = (auth_user_id) -> Promise.try () ->
  _getProfileWhere
    "#{tables.user.profile.tableName}.auth_user_id": auth_user_id
    "#{tables.user.project.tableName}.sandbox": false
  .then (profiles) ->
    _.indexBy profiles, 'id'

getFirst = (userId) ->
  tables.user.profile()
  .where(auth_user_id: userId)
  .then singleRow
  .then (userState) ->
    if not userState
      tables.user.profile()
      .insert
        auth_user_id: userId
      .then () ->
        return {}
    else
      result = userState
      delete result.id
      return result

getCurrentSessionProfile = (session) ->
  currentProfile(session)

update = (profile, auth_user_id, safe = safeProfile) ->
  Promise.throw("auth_usr_id is undefined") unless auth_user_id

  userProfileSvc.getById profile.id
  .then (profileProject) ->
    if profileProject? and !_.isEmpty(toUpdate = _.pick(profile, ['properties_selected']))
      projectSvc.update profileProject.project_id, toUpdate
  .then () ->
    # logger.debug "profile update"
    # logger.debug profile, true
    userProfileSvc.update {id: profile.id, auth_user_id: auth_user_id}, profile, safe
  .then (userState) ->
    if not userState
      return {}
    result = userState
    delete result.id
    return result

_hasProfileStateChanged = (profile, partialState) ->
  #avoid unnecessary saves as there is the possibility for race conditions
  needsSave = false
  for key,part of partialState
    if !_.isEqual part, profile[key]
      needsSave = true
      break
  needsSave

updateCurrent = (session, partialState, safe) ->
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
  getProfiles: getProfiles
  getClientProfiles: getClientProfiles
  getCurrentSessionProfile: getCurrentSessionProfile
  updateCurrent: updateCurrent
  update: update
  getFirst: getFirst
  create: create
  createForProject: createForProject
