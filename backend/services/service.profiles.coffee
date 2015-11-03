Promise = require 'bluebird'
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
tables = require '../config/tables'
{singleRow} = require '../utils/util.sql.helpers'
{currentProfile} = require '../utils/util.session.helpers'
profileSvc = (require './services.user').user.profiles
projectSvc = (require './services.user').project

analyzeValue = require '../../common/utils/util.analyzeValue'

cols =  [
  "#{tables.user.profile.tableName}.id as id", "#{tables.user.profile.tableName}.auth_user_id as auth_user_id",
  'filters', 'properties_selected', 'map_toggles',
  'map_position', 'map_results','parent_auth_user_id',
  "#{tables.user.profile.tableName}.rm_modified_time as rm_modified_time",
  "#{tables.user.profile.tableName}.rm_inserted_time as rm_inserted_time",
  'project_id',
  "#{tables.user.project.tableName}.rm_modified_time as #{tables.user.project.tableName}_rm_modified_time",
  "#{tables.user.project.tableName}.rm_inserted_time as #{tables.user.project.tableName}_rm_inserted_time",
  "#{tables.user.project.tableName}.name as #{tables.user.project.tableName}_name",
  "#{tables.user.project.tableName}.archived as #{tables.user.project.tableName}_archived",
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

safeProject = ['id', 'auth_user_id', 'archived', 'name', 'minPrice', 'maxPrice', 'beds', 'baths', 'sqft', 'properties_selected']

toReturn = safe.concat ['id']

get = (id, withProject = true) ->
  return tables.user.profile().where(id: id) unless withProject

create = (newProfile, project) ->
  logger.debug 'PROFILE SVC: creating a profile'
  Promise.try () ->
    tables.user.project()
    .returning('id')
    .insert(_.pick project, safeProject)
    .then (inserted) ->
      inserted?[0]
  .then (maybeProjectId) ->
    if maybeProjectId
      newProfile.project_id = maybeProjectId
    tables.user.profile()
    .returning(toReturn)
    .insert(_.pick newProfile, safe)
  .then (inserted) ->
    inserted?[0]
  .catch (error) ->
    logger.error analyzeValue error
    throw new Error('Error creating new project')

getProfiles = (auth_user_id, withProject = true) -> Promise.try () ->
  noProjQ = tables.user.profile().where(auth_user_id: auth_user_id)
  logger.debug noProjQ.toString()
  noProjQ.then (profilesNoProject) ->
    hasAProject = _.some profilesNoProject, (p) -> p.project_id?

    logger.debug "hasAProject: #{hasAProject}"
    logger.debug "withProject: #{withProject}"

    if withProject and hasAProject
      q =  tables.user.profile().select(cols...).leftJoin(tables.user.project.tableName,
      tables.user.project.tableName + '.id', tables.user.profile.tableName + '.project_id')
      .where("#{tables.user.profile.tableName}.auth_user_id": auth_user_id)
      # logger.debug q.toString()
      return q

    unless profilesNoProject?.length
      logger.debug "no profiles exist for auth_user_id: #{auth_user_id}. Creating"
      return create(auth_user_id: auth_user_id)
    logger.debug "returning profilesNoProject: #{JSON.stringify profilesNoProject}"
    profilesNoProject

  .then (profiles) ->
    logger.debug profiles
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
  profileSvc.getById profile.id
  .then (profileProject) ->
    logger.debug profileProject
    if profileProject?
      projectSvc.update profileProject.project_id, _.pick(profile, ['properties_selected'])
  .then () ->
    profileSvc.update profile.id, profile, safe
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
  get: get
  getProfiles: getProfiles
  getCurrent: getCurrent
  updateCurrent: updateCurrent
  update: update
  getFirst: getFirst
  create: create
