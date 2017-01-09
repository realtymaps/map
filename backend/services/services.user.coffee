logger = require('../config/logger').spawn('services:user')
Promise = require 'bluebird'
tables = require '../config/tables'
dbs = require '../config/dbs'
oldCrud = require '../utils/crud/util.crud.service.helpers'
EzCrud = require '../utils/crud/util.ezcrud.service.helpers'
{basicColumns} = require '../utils/util.sql.columns'
stripeServices = null
emailServices = null
{UserIdDoesNotExistError} =  require '../utils/errors/util.errors.vero'
{CustomerDoesNotExistError} =  require '../utils/errors/util.errors.stripe'


require('../services/services.email').emailPlatform.then (svc) ->
  emailServices = svc
require('../services/payment/stripe')().then (svc) ->
  stripeServices = svc


group = new EzCrud(tables.auth.group)
permission = new EzCrud(tables.auth.permission)
m2m_group_permission = new EzCrud(tables.auth.m2m_group_permission)
m2m_user_permission = new EzCrud(tables.auth.m2m_user_permission)
m2m_user_group = new EzCrud(tables.auth.m2m_user_group)
profile = new EzCrud(tables.user.profile)

getMany = ({user, m2mCrud, linkCrud, field} = {}) ->
  user["#{field}s"] = []

  linkName = linkCrud.dbFn.tableName
  m2mName = m2mCrud.dbFn.tableName

  m2mCrud.dbFn().join(linkName, "#{linkName}.id", "#{m2mName}.#{field}_id")
  .select("#{m2mName}.id", "#{m2mName}.user_id", "#{linkName}.*")
  .where(user_id: user.id)
  .then (results) ->
    user["#{field}s"] = results

mapFks = (user) ->
  getPermissions = getMany {user, m2mCrud: m2m_user_permission, linkCrud: permission, field: 'permission'}
  getGroups = getMany {user, m2mCrud: m2m_user_group, linkCrud: group, field: 'group'}
  Promise.join(getPermissions, getGroups)
  .then ->
    user



class UserCrud extends EzCrud

  init: () =>
    # taking care of inits here fore internal svcs so they can be overridden
    # logger.debug 'INIT UserCrud Service'
    @permissions = m2m_user_permission

    @groups = m2m_user_group

    @clients = profile

    return @

  getAll: (entity = {}, options = {}) ->
    options = query: @dbFn().select(basicColumns.userSafe)
    super(entity, options)
    .then (users) ->
      Promise.map users, (user) ->
        mapFks(user)


  getById: (entity = {}, options = {}) ->
    options =
      query: @dbFn().select(basicColumns.userSafe)
    super(entity, options)
    .then ([result]) ->
      mapFks(result)

  clone: ->
    new UserCrud(@dbFn, @options)

  delete: (idEntity, options = {}) =>
    dbs.transaction 'main', (transaction) =>
      options.transaction = transaction

      @dbFn().select(basicColumns.userSafe)
      .where(idEntity)
      .then ([wholeEntity]) =>

        logger.debug -> "wholeEntity"
        logger.debug -> wholeEntity

        veroId = emailServices.user.getUniqueUserId(wholeEntity)
        logger.debug -> "veroId: #{veroId}"

        stripe = if !wholeEntity.stripe_customer_id?
          Promise.resolve()
        else
          stripeServices.customers.remove(wholeEntity)
          .then () -> logger.debug -> 'stripe customer removal success'
          .catch CustomerDoesNotExistError.is, (err) ->
            logger.debug -> 'Stripe customer does not exist already. we\'re good'

        vero = emailServices.vero.deleteUser(veroId)
          .then () -> logger.debug -> 'vero customer removal success'
          .catch UserIdDoesNotExistError.is, (error) ->
            logger.debug -> 'Vero customer does not exist already. we\'re good'

        #clean up third party services
        Promise.join(stripe, vero)
        .then () =>
          super(idEntity, options)

module.exports = {
  user: new UserCrud(tables.auth.user).init(false)
  accountUseTypes: new oldCrud.Crud(tables.lookup.accountUseTypes)
  project: new EzCrud(tables.user.project)
  company: new oldCrud.Crud(tables.user.company)
  drawnShapes: new oldCrud.Crud(tables.user.drawnShapes)
  notes: new oldCrud.Crud(tables.user.notes)
  profile
  group
  permission
  m2m_group_permission
  m2m_user_permission
  m2m_user_group
}
