Promise = require 'bluebird'
bcrypt = require 'bcrypt'
_ = require 'lodash'
logger = require '../config/logger'
tables = require '../config/tables'
sqlHelpers = require '../utils/util.sql.helpers'
singleRow = sqlHelpers.singleRow
{currentProfile} = require '../utils/util.session.helpers'
userProfileSvc = (require './services.user').user.profiles
projectSvc = (require './services.user').project

safeProject = sqlHelpers.columns.project
safeProfile = sqlHelpers.columns.profile

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

getCurrent = (session) ->
  currentProfile(session)

update = (profile) ->
  userProfileSvc.getById profile.id
  .then (profileProject) ->
    if profileProject?
      projectSvc.update profileProject.project_id, _.pick(profile, ['properties_selected'])
  .then () ->
    # logger.debug "profile update"
    # logger.debug profile, true
    userProfileSvc.update profile.id, profile, safeProfile
  .then (userState) ->
    if not userState
      return {}
    result = userState
    delete result.id
    return result

updateCurrent = (session, partialState) ->
  # need the id for lookup, so we don't want to allow it to be set this way
  delete partialState.id

  #avoid unnecessary saves as there is the possibility for race conditions
  needsSave = false
  profile = currentProfile(session)
  for key,part of partialState
    if !_.isEqual part, profile[key]
      needsSave = true
      break
#  logger.debug "service.user needsSave: #{needsSave}"
  if needsSave
    _.extend(profile, partialState)
    session.saveAsync()  # save immediately to prevent problems from overlapping AJAX calls
  update(profile)

module.exports =
  getProfiles: getProfiles
  getCurrent: getCurrent
  updateCurrent: updateCurrent
  update: update
  getFirst: getFirst
  create: create
