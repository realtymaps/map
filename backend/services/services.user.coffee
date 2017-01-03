logger = require('../config/logger').spawn('services:user')
Promise = require 'bluebird'
tables = require '../config/tables'
dbs = require '../config/dbs'
oldCrud = require '../utils/crud/util.crud.service.helpers'
EzCrud = require '../utils/crud/util.ezcrud.service.helpers'
{joinColumns, basicColumns} = require '../utils/util.sql.columns'
stripeServices = null
emailServices = null
{UserIdDoesNotExistError} =  require '../utils/errors/util.errors.vero'
{CustomerDoesNotExistError} =  require '../utils/errors/util.errors.stripe'


require('../services/services.email').emailPlatform.then (svc) ->
  emailServices = svc
require('../services/payment/stripe')().then (svc) ->
  stripeServices = svc


module.exports.accountUseTypes = new oldCrud.Crud(tables.lookup.accountUseTypes)

module.exports.group = new oldCrud.Crud(tables.auth.group)
module.exports.permission = new oldCrud.Crud(tables.auth.permission)
module.exports.m2m_group_permission = new oldCrud.Crud(tables.auth.m2m_group_permission)
module.exports.m2m_user_permission = new oldCrud.Crud(tables.auth.m2m_user_permission)
module.exports.m2m_user_group = new oldCrud.Crud(tables.auth.m2m_user_group)

module.exports.profile = new oldCrud.Crud(tables.user.profile)
module.exports.project = new oldCrud.Crud(tables.user.project)
module.exports.company = new oldCrud.Crud(tables.user.company)
module.exports.drawnShapes = new oldCrud.Crud(tables.user.drawnShapes)
module.exports.notes = new oldCrud.Crud(tables.user.notes)


class UserCrud extends EzCrud
  constructor: () ->
    super(arguments...)

  init: () =>
    # taking care of inits here fore internal svcs so they can be overridden
    # logger.debug 'INIT UserCrud Service'
    @permissions = new oldCrud.ThenableHasManyCrud(tables.auth.permission, joinColumns.permission,
      module.exports.m2m_user_permission, 'permission_id', undefined,
      "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @groups = new oldCrud.ThenableHasManyCrud(tables.auth.group, joinColumns.groups,
      module.exports.m2m_user_group, 'group_id', undefined,
      "#{tables.auth.m2m_user_group.tableName}.id").init(arguments...)

    @clients = new oldCrud.ThenableHasManyCrud(tables.auth.user, joinColumns.client,
      module.exports.profile, undefined, undefined,
      "#{tables.user.profile.tableName}.id").init(arguments...)

    return @

  getAll: (entity = {}, options = {}) ->
    options =
      query: @dbFn().select(basicColumns.userSafe)
    super(entity, options)

  getById: (entity = {}, options = {}) ->
    options =
      query: @dbFn().select(basicColumns.userSafe)
    super(entity, options)

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

module.exports.user = new UserCrud(tables.auth.user).init(false)
