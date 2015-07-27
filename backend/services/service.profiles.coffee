Promise = require "bluebird"
bcrypt = require 'bcrypt'
_ = require 'lodash'

logger = require '../config/logger'
{userData} = require "../config/tables"
{auth_user_profile, project} = userData
{singleRow} = require '../utils/util.sql.helpers'
{currentProfile} = require '../utils/util.session.helpers'

cols =  [
  "#{auth_user_profile.tableName}.id as id", 'auth_user_id',
  'filters', 'properties_selected', 'map_toggles',
  'map_position', 'map_results','parent_auth_user_id',
  "#{auth_user_profile.tableName}.rm_modified_time as rm_modified_time",
  "#{auth_user_profile.tableName}.rm_inserted_time as rm_inserted_time",
  "#{auth_user_profile.tableName}.name as name",
  'project_id',
  "#{project.tableName}.rm_modified_time as #{project.tableName}_rm_modified_time",
  "#{project.tableName}.rm_inserted_time as #{project.tableName}_rm_inserted_time",
  "#{project.tableName}.name as #{project.tableName}_name",
]

safe = [
  'filters'
  'properties_selected'
  'map_toggles'
  'map_position'
  'map_results'
  'parent_auth_user_id'
  'auth_user_id'
  'name'
  'project_id'
]

toReturn = safe.concat ['id']

get = (id, withProject = true) ->
  return auth_user_profile().where(id: id) unless withProject

create = (auth_user_id) ->
  auth_user_profile().insert(auth_user_id: auth_user_id).returning(toReturn)

getProfiles = (auth_user_id, withProject = true) -> Promise.try () ->
  noProjQ = auth_user_profile().where(auth_user_id: auth_user_id)
  logger.debug noProjQ.toString()
  noProjQ.then (profilesNoProject) ->
    hasAProject = _.some profilesNoProject, (p) -> !_.isUndefined(p.project_id)

    logger.debug "hasAProject: #{hasAProject}"
    logger.debug "withProject: #{withProject}"

    if !withProject and !hasAProject
      q =  auth_user_profile().select(cols...).innerJoin(project.tableName,
      project.tableName + ".id", auth_user_profile.tableName + '.project_id')
      .where(auth_user_id: auth_user_id)
      # logger.debug q.toString()
      return q

    unless profilesNoProject?.length
      logger.debug "no profiles exist for auth_user_id: #{auth_user_id}. Creating"
      return create(auth_user_id)
    logger.debug "returning profilesNoProject: #{JSON.stringify profilesNoProject}"
    profilesNoProject

  .then (profiles) ->
    logger.debug profiles
    _.indexBy profiles, 'id'

getFirst = (userId) ->
  singleRow(auth_user_profile().where(auth_user_id: userId))
  .then (userState) ->
    if not userState
      userData.auth_user_profile()
      .insert
        auth_user_id: userId
      .then () ->
        return {}
    else
      result = userState
      delete result.id
      return result

update = (profile) ->
  q = userData.auth_user_profile()
  .where(_.pick profile, ['auth_user_id', 'id'])
  .update(_.pick profile, safe)
  # logger.debug q.toString()
  singleRow(q)
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
  updateCurrent: updateCurrent
  update: update
  getFirst: getFirst
