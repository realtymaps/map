Promise = require 'bluebird'
_ = require 'lodash'
logger = require '../config/logger'
tables = require '../config/tables'
{singleRow} = require '../utils/util.sql.helpers'
{basicColumns} = require '../utils/util.sql.columns'
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
createForProject = ({newProfile, transaction = null}) ->
  if !newProfile.project_id? then throw new Error '`project_id` is required to create profile.'
  tables.user.profile(transaction: transaction)
  .returning safeProfile
  .insert(_.pick newProfile, safeProfile)

getProfiles = (auth_user_id) -> Promise.try () ->
  userProfileSvc.getAll "#{tables.user.profile.tableName}.auth_user_id": auth_user_id

  .then (profiles) ->
    sandbox = _.find profiles, (p) -> p.sandbox is true
    if sandbox?
      profiles
    else
      logger.debug "No sandbox exists for auth_user_id: #{auth_user_id}. Creating..."
      create auth_user_id: auth_user_id, sandbox: true
      .then () ->
        userProfileSvc.getAll "#{tables.user.profile.tableName}.auth_user_id": auth_user_id

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
  getCurrentSessionProfile: getCurrentSessionProfile
  updateCurrent: updateCurrent
  update: update
  getFirst: getFirst
  create: create
  createForProject: createForProject
