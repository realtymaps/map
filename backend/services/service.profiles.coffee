Promise = require 'bluebird'
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
tables = require '../config/tables'
{singleRow} = require '../utils/util.sql.helpers'
{currentProfile} = require '../utils/util.session.helpers'
userProfileSvc = (require './services.user').user.profiles
projectSvc = (require './services.user').project

analyzeValue = require '../../common/utils/util.analyzeValue'

cols =  [
  "#{tables.user.profile.tableName}.id as id"
  "#{tables.user.profile.tableName}.filters"
  "#{tables.user.profile.tableName}.map_toggles"
  "#{tables.user.profile.tableName}.map_position"
  "#{tables.user.profile.tableName}.map_results"
  "#{tables.user.profile.tableName}.parent_auth_user_id"

  "#{tables.user.project.tableName}.id as project_id"
  "#{tables.user.project.tableName}.auth_user_id"
  "#{tables.user.project.tableName}.name"
  "#{tables.user.project.tableName}.sandbox"
  "#{tables.user.project.tableName}.archived"
  "#{tables.user.project.tableName}.properties_selected"
  "#{tables.user.project.tableName}.rm_modified_time"
  "#{tables.user.project.tableName}.rm_inserted_time"
]

safe = [
  'filters'
  'map_toggles'
  'map_position'
  'map_results'
  'parent_auth_user_id'
  'auth_user_id'
  'project_id'
]

safeProject = ['id', 'auth_user_id', 'archived', 'sandbox', 'name', 'minPrice', 'maxPrice', 'beds', 'baths', 'sqft', 'properties_selected']

toReturn = safe.concat ['id']

create = (newProfile) ->
  Promise.try () ->
    tables.user.project()
    .returning('id')
    .insert(_.pick newProfile, safeProject)
  .then (projectIds) ->
    newProfile.project_id = projectIds[0]
    tables.user.profile()
    .returning(toReturn)
    .insert(_.pick newProfile, safe)
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
    logger.debug profiles
    _.indexBy profiles, 'id'

getFirst = (userId) ->
  singleRow(tables.user.profile().where(auth_user_id: userId))
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
    logger.debug profileProject
    if profileProject?
      projectSvc.update profileProject.project_id, _.pick(profile, ['properties_selected'])
  .then () ->
    userProfileSvc.update profile.id, profile, safe
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
