Promise = require 'bluebird'
_ = require 'lodash'
logger = require('../config/logger').spawn('service:profiles')
tables = require '../config/tables'
db = require('../config/dbs').get('main')
clsFactory = require '../utils/util.cls'
profileErr = require '../utils/errors/util.error.profile'
{singleRow, whereAndWhereIn} = require '../utils/util.sql.helpers'
{basicColumns, joinColumns} = require '../utils/util.sql.columns'

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

createSandbox = (auth_user_id) ->
  create(auth_user_id: auth_user_id, sandbox: true, can_edit: true)

# if we already know project, we can use this routine
createForProject = (newProfile, transaction = null) ->
  if !newProfile.project_id? then throw new Error '`project_id` is required to create profile.'
  tables.user.profile(transaction: transaction)
  .returning safeProfile
  .insert(_.pick newProfile, safeProfile)

# returns the main query for profile & project list query
# `where` can honor a test on any field in `auth_user`, `user_project`, `user_profile`
getProfileWhere = (where = {}) ->
  tables.user.profile()
  .select(joinColumns.profile)
  .select(
    db.raw("auth_user.first_name || ' ' || auth_user.last_name as parent_name")
  )
  .select("auth_user.account_image_id as parent_image_id")
  .select("#{tables.user.company.tableName}.name as company_name")
  .where(where)
  .innerJoin(tables.user.project.tableName,"#{tables.user.profile.tableName}.project_id", "#{tables.user.project.tableName}.id")
  .leftOuterJoin(tables.auth.user.tableName, "#{tables.auth.user.tableName}.id", "#{tables.user.profile.tableName}.parent_auth_user_id")
  .leftOuterJoin(tables.user.company.tableName, "#{tables.user.company.tableName}.id", "#{tables.auth.user.tableName}.company_id")

# internal profile update
_updateProfileWhere = (profile, where) ->
  safeUpdate = _.pick(profile, safeProfile)
  q = tables.user.profile()
  .update(safeUpdate)
  .where(where)
  logger.debug () -> q.toString()
  q

# general purpose getAll endpoint for profile model (no project fields)
getAll = (entity) ->
  tables.user.profile()
  .select(safeProfile)
  .where(entity)

getAllBulk = (entity) ->
  query = tables.user.profile()
  .select(safeProfile)

  query = whereAndWhereIn(query, entity)

  logger.debug () -> "query:\n#{query.toString()}"
  query

# this gives us profiles for a subscribing user, getting and/or creation a sandbox if applicable
# Note: this differs from a usual "getAll" endpoint in that we bundle some project fields with profile results
getProfiles = ({auth_user_id, parent_auth_user_id} = {}) -> Promise.try () ->
  l = logger.spawn('getProfiles')
  l.debug -> {auth_user_id, parent_auth_user_id}
  entity = "#{tables.user.profile.tableName}.auth_user_id": auth_user_id

  if typeof(parent_auth_user_id) != 'undefined' #allow for nulls
    entity["#{tables.user.profile.tableName}.parent_auth_user_id"] = parent_auth_user_id

  l.debugQuery(getProfileWhere(entity))
  .then (profiles) ->
    sandbox = _.find profiles, (p) -> p.sandbox is true
    if sandbox?
      profiles
    else
      logger.debug -> "No sandbox exists for auth_user_id: #{auth_user_id}. Creating..."
      createSandbox(auth_user_id)
      .then () ->
        # re-fetch for full list w/ ids
        l.debugQuery(getProfileWhere("#{tables.user.profile.tableName}.auth_user_id": auth_user_id))

  .then (profiles) ->
    _.indexBy profiles, 'id'

# this gives us profiles for a non-subscribing (client) user, forego dealing with sandbox
getClientProfiles = (auth_user_id) -> Promise.try () ->
  getProfileWhere
    "#{tables.user.profile.tableName}.auth_user_id": auth_user_id
    "#{tables.user.project.tableName}.sandbox": false
  .then (profiles) ->
    _.indexBy profiles, 'id'

getCurrentSessionProfile = (session) ->
  try
    if !session?
      logger.debug -> 'no session'
      req = clsFactory().namespace.get 'req'
      if !req? || !('session' of req)
        logger.debug -> 'no session in req'
        rmapsNamespace = process.namespaces.rmaps
        logger.error "Unable to fetch `req` from namespace object: #{rmapsNamespace}"
        throw new profileErr.CurrentProfileError("Unable to acquire `req` from rmaps namespace.")
      session = req.session
  catch error
    throw new profileErr.CurrentProfileError(error.message)

  if !('current_profile_id' of session) and !session.profiles
    throw new profileErr.CurrentProfileError("Error getting current profile: session.current_profile_id=#{session.current_profile_id}, session.profiles.length=#{session.profiles?.length}")

  profile = session.profiles[session.current_profile_id]
  if !profile?
    logger.error "session: #{JSON.stringify(_.omit(session,['profiles']))}"
    logger.error "session profile ids: #{JSON.stringify(Object.keys(session.profiles))}"
    throw new profileErr.CurrentProfileError("Error while acquiring current profile.")

  logger.debug -> "returning profile"
  logger.debug -> profile
  profile

# The parameter "profile" may actually be an entity with both project & profile fields, but doesn't have to be
update = (profile, auth_user_id) -> Promise.try () ->
  if !auth_user_id? then throw new Error("auth_user_id is undefined")

  where = {id: profile.id, auth_user_id: auth_user_id}
  _updateProfileWhere(profile, where)
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

updateCurrent = (session, partialState = {}) ->
  sessionProfile = getCurrentSessionProfile(session)

  saveSessionPromise = if _hasProfileStateChanged(sessionProfile, partialState)
    _.extend(sessionProfile, partialState)
    session.saveAsync() #save immediately to prevent problems from overlapping AJAX calls
  else
    Promise.resolve()

  saveSessionPromise.then () ->
    update(sessionProfile, session.userid)

module.exports = {
  getAll
  getAllBulk
  getProfiles
  getClientProfiles
  getCurrentSessionProfile
  updateCurrent
  update
  create
  createSandbox
  createForProject
  getProfileWhere
}
