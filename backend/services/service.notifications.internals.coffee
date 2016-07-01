Promise = require 'bluebird'
twilio = require 'twilio'
_ = require 'lodash'
memoize = require 'memoizee'
clone = require 'clone'
externalAccounts = require '../services/service.externalAccounts'
errorHelpers = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
emailConfig = require '../config/email'
logger = require('../config/logger').spawn('service:notifications:internals')
analyzeValue = require '../../common/utils/util.analyzeValue'
{VeroEmailError, BasicEmailError, SmsError} = require '../utils/errors/util.error.notifications'
promisedVeroService = require '../services/email/vero'
notifyConfigInternals = require '../services/service.notification.config.internals'

twilioClientPromise = Promise.try () ->
  externalAccounts.getAccountInfo('twilio')
  .then (accountInfo) ->
    client: twilio(accountInfo.username, accountInfo.api_key)
    smsNumber: accountInfo.other.number
  .catch errorHelpers.isUnhandled, (err) ->
    throw new errorHelpers.PartiallyHandledError(err, 'Twilio login not found in environment. No client')
twilioClientPromise = memoize.promise(twilioClientPromise, maxAge: 15*60*1000)


getSmsOptions = (to, subject, number) ->
  to = '+1'+to if '+' not in to

  from: number
  to: to
  body: subject


getEmailOptions = (to, subject, message) ->
  to = [to] if not Array.isArray(to)
  # from: NA    # default is the account used for making the SMTP transport
  to: to
  subject: subject
  text: message
  # html: <template>    # can leverage any html templating later if/when we need


buildBasicEmail = (options) ->
  options = clone options

  logger.debug options
  # set up full email message including error & info as needed
  msgContent = []
  if options.message
    msgContent.push options.message
    delete options.message

  # options.error flags whether to include the options data
  if options.error
    msgContent.push 'Details:'
    msgContent.push ("  #{k}: #{v}" for k, v of options).join '\n'

  msgContent.join '\n\n'


sendBasicEmail = (row, options) ->
  emails = options?.emails || [row.email]
  emailIds = options?.emailIds || [row.id]

  options = _.omit options, ['emails', 'emailIds']

  # send email
  if !emails?.length
    return Promise.resolve()

  message = buildBasicEmail options

  emailOptions = getEmailOptions(emails, "NOTIFICATION: #{options.subject}", message)

  logger.debug emailOptions

  # was hoping to memoize emailConfig.getMailer() as mailerPromise
  # some odd reason the below memoize will not work (maybe due to memoize.promise of memoize.promise via externalAccounts?)
  # memoize.promise(emailConfig.getMailer, maxAge: 15*60*1000)
  emailConfig.getMailer()
  .then (mailer) ->
    mailer.sendMailAsync emailOptions
  .catch (err) ->
    throw new BasicEmailError(emailIds, err, 'Bulk email error')


sendSms = (row, options) -> Promise.try () ->
  if !row.cell_phone
    throw new SmsError row.id, 'cell_phone required'

  cellPhone = options.cell_phone || row.cell_phone

  twilioClientPromise
  .then (twilioInfo) ->
    sendSmsAsync = Promise.promisify twilioInfo.client.sendSms
    sendSmsAsync(getSmsOptions(cellPhone, options.subject, twilioInfo.smsNumber))
  .catch errorHelpers.isUnhandled, (err) ->
    throw new SmsError(row.id, err, 'Twilio Error. ')
  .catch (err) ->
    details = analyzeValue.getSimpleDetails(err)
    logger.error "notification error: #{details}"

    tables.user.notificationQueue()
    .insert {
      options
      config_notification_id: row.id
      error: details
      attempts: 1
    }

sendEmailVero = (row, options) -> Promise.try () ->
  if !options?.type?
    throw new VeroEmailError row.config_notification_id, 'notfication.type required for vero email notification!'

  logger.debug "@@@@@@@@@@@@@@@ options @@@@@@@@@@@@@@@"
  logger.debug options

  promisedVeroService
  .then (vero) -> Promise.try () ->
    options.authUser =
        first_name: row.first_name
        last_name: row.last_name
        email: row.email

    options.notificationType = switch options.type
      when 'propertySaved'
        'notificationPropertiesSaved'
      else
        null

    if !vero.events[options.notificationType]?
      throw new VeroEmailError row.config_notification_id, 'notification.type invalid for vero email notification!'
    vero.events[options.notificationType](options)

# Build a list of users that are parents of a childId
#
# * `id` {[int]} childId.
# * `project_id` {[int]}.
#
# Returns Array<tables.auth.user>
getParentUsers = ({id, project_id}) ->
  childId = id

  tables.auth.user()
  .select(notifyConfigInternals.explicitUserColumns)
  .innerJoin(tables.user.profile.tableName,
    "#{tables.user.profile.tableName}.parent_auth_user_id",
    "#{tables.auth.user.tableName}.id")
  .where
    "#{tables.user.profile.tableName}.auth_user_id": childId
    "#{tables.user.profile.tableName}.project_id": project_id

# Build a list of users that are children of a parent_id.
# Based on profile rows.parent_id
#
# * `id` {[int]} parentId.
# * `project_id` {[int]}.
#
# Returns Array<tables.auth.user>
getChildUsers = ({id, project_id}) ->
  parentId = id

  tables.auth.user()
  .select(notifyConfigInternals.explicitUserColumns)
  .innerJoin(tables.user.profile.tableName,
    "#{tables.user.profile.tableName}.auth_user_id",
    "#{tables.auth.user.tableName}.id")
  .where
    "#{tables.user.profile.tableName}.parent_auth_user_id": parentId
    "#{tables.user.profile.tableName}.project_id": project_id

# Build a list of users that are siblings in a project
# NOT including the calling user
#
# * `id` {[int]} childId.
# * `project_id` {[int]}.
#
# Returns Array<tables.auth.user>
getSiblingUsers = ({id, project_id}) ->
  childId = id

  tables.auth.user()
  .select(notifyConfigInternals.explicitUserColumns)
  .innerJoin(tables.user.profile.tableName,
    "#{tables.user.profile.tableName}.auth_user_id",
    "#{tables.auth.user.tableName}.id")
  .where
    "#{tables.user.profile.tableName}.project_id": project_id
  .whereNot
    "#{tables.user.profile.tableName}.auth_user_id": childId

# Public: [Description]
#
# * `to` Whom to send a notification to. as {[string]}.
#   children, childrenSelf, childrenself, children self
#   parents, parentsSelf, parentsself, parents self
#   all, allSelf, allself, all self, all Self
#   siblings, siblingsSelf, siblings self, siblings Self, siblings self
#
#  Note: the location of the self string does not matter it could be prepended or appended. caps or no caps
#
# * `id` - parentId or childId that is targeted to send to
# * `project_id` - project relevant to this notification
# Returns the [Description] as `undefined`.
getUsers = ({to, id, project_id}) ->
  logger.debug "@@@@ getUsers opts @@@@"
  logger.debug {to, id, project_id}
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@"

  switch true #use regex for flex
    when /children/.test to
      logger.debug 'going to children'
      childrenPromise = getChildUsers({id, project_id})
    when /siblings/.test to
      logger.debug 'going to siblings'
      siblingPromise = getSiblingUsers({id, project_id})
    when /parents/.test to
      logger.debug 'going to parents'
      parentsPromise = getParentUsers({id, project_id})
    when /all/.test to
      logger.debug 'going to all'
      childrenPromise = getChildUsers({id, project_id})
      parentsPromise = getParentUsers({id, project_id})
      siblingPromise = getSiblingUsers({id, project_id})
    else
      #do nothing as we can check for self as well

  selfPromise = Promise.resolve []

  if to.match /self/i
    logger.debug 'going to self'
    selfPromise = tables.auth.user()
    .select(notifyConfigInternals.userColumns)
    .where {id}

  Promise.join parentsPromise, childrenPromise, siblingPromise, selfPromise,
    (downUsers=[], upUsers=[], siblingPromise=[], selfUsers=[]) ->
      users = downUsers.concat upUsers, siblingPromise, selfUsers

      # remove dupes as a parent request does not need siblings and children
      # this allows us to not insert another argument of calling type (child or parent)
      _.uniq users, "id"


enqueue = ({verify, configRowsQuery, options, verbose, from, verifyConfigRows}) ->
  logger.debug () -> "@@@@@@ #{from}: enqueue opts @@@@@@"
  logger.debug {verify, options, verbose}
  logger.debug "@@@@@@@@@@@@@@@@@@@@@@@@@@"

  if verbose
    logger.debug configRowsQuery.toString()

  configRowsQuery
  .returning('id')
  .then (configRows) ->

    if !configRows?.length
      if verifyConfigRows #handy for debuging
        throw new Error('Nothing enqueued.')
      else
        if verbose
          logger.warn "@@@@ Nothing enqueued into #{tables.user.notificationQueue.tableName} @@@@"
      return

    logger.debug () -> "@@@@ #{from}: mapping #{configRows.length} configRows @@@@"
    userRows = for row in configRows
      do (row) -> {
        config_notification_id: row.id
        options
      }

    logger.debug () -> "@@@@ #{from}: enqueuing to #{tables.user.notificationQueue.tableName} @@@@"
    tables.user.notificationQueue()
    .insert(userRows)
    .returning('id')
    .then (rows) -> Promise.try () ->
      if verify and !rows?.length
        throw new Error('Nothing enqueued.')

      logger.debug () -> "@@@@ #{from}: SUCCESS!!!! #{rows.length} rows enqueued. @@@@"
      rows



sendHandles =
  email: sendBasicEmail
  sms: sendSms
  emailVero: sendEmailVero
  default: sendEmailVero

module.exports = {
  twilioClientPromise
  getSmsOptions
  getEmailOptions
  buildBasicEmail
  sendBasicEmail
  sendSms
  sendEmailVero
  sendHandles
  distribute:{
    getUsers
    getChildUsers
    getParentUsers
    getSiblingUsers
  }
  enqueue
}
