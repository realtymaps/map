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
{VeroEmailError, BasicEmailError, SmsError} = require '../utils/errors/util.error.notifcations'
promisedVeroService = require '../services/email/vero'
notifyConfigInternals = require '../services/service.notifications.internals'

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
  if !options?.notificationType?
    throw new VeroEmailError row.config_notification_id, 'notificationType required for vero email notification!'

  logger.debug "@@@@@@@@@@@@@@@ options @@@@@@@@@@@@@@@"
  logger.debug options

  promisedVeroService
  .then (vero) -> Promise.try () ->
    opts =
      authUser:
        first_name: row.first_name
        last_name: row.first_name

    #extend opts to allow options like properties
    _.extend opts, _.omit options, ['notificationType']

    logger.debug "@@@@@@@@@@@@@@@ opts @@@@@@@@@@@@@@@"
    logger.debug opts

    if !vero.events[options.notificationType]?
      throw new VeroEmailError row.config_notification_id, 'notificationType invalid for vero email notification!'

    vero.events[options.notificationType](opts)

distribute = do ->
  # Build a list of users that are parents of a childId
  #
  # * `childId` {[int]}.
  # * `project_id` {[int]}.
  #
  # Returns Array<tables.auth.user>
  getParentUsers = ({childId, project_id}) ->
    tables.auth.user()
    .select(notifyConfigInternals.userColumns)
    .innerJoin(tables.user.profile,
      "#{tables.user.profile.tableName}.parent_auth_user_id",
      "#{tables.auth.user.tableName}.id"
    )
    .where
      "#{tables.user.profile.tableName}._auth_user_id": childId
      "#{tables.user.profile.tableName}.project_id": project_id

  # Build a list of users that are children of a parent_id.
  # Based on profile rows.parent_id
  #
  # * `parentId` {[int]}.
  # * `project_id` {[int]}.
  #
  # Returns Array<tables.auth.user>
  getChildUsers = ({parentId, project_id}) ->
    tables.auth.user()
    .select(notifyConfigInternals.userColumns)
    .innerJoin(tables.user.profile,
      "#{tables.user.profile.tableName}.auth_user_id",
      "#{tables.auth.user.tableName}.id"
    )
    .where
      "#{tables.user.profile.tableName}.parent_auth_user_id": parentId
      "#{tables.user.profile.tableName}.project_id": project_id


  # Public: [Description]
  #
  # * `{to` Whom to send a notification to. as {[string]}.
  #   children, childrenSelf,
  #   parents, parentsSelf,
  #   all, allSelf
  #
  # * `configRow}` The config_notifcation row as {[object]}.
  #
  # Returns the [Description] as `undefined`.
  getUsers = ({to, id, project_id}) ->

    childrenPromise = Promise.resolve []
    parentsPromise = Promise.resolve []

    switch to #use regex for flex
      when to.match /children/
        parentsPromise = getChildUsers({id, project_id})
      when to.match /parents/
        childrenPromise = getParentUsers({id, project_id})
      when to.match /all/
        parentsPromise = getChildUsers({id, project_id})
        childrenPromise = getParentUsers({id, project_id})
      else
        return Promise.resolve []

    selfPromise = Promise.resolve []

    if to.match /self/i
      selfPromise = tables.auth.user()
      .select(notifyConfigInternals.userColumns)
      .where {id}

    Promise.join parentsPromise, childrenPromise, selfPromise,
      (downUsers, upUsers, selfUsers) ->
        downUsers.concat upUsers, selfUsers

  {
    getParentUsers
    getChildUsers
    getUsers
  }

enqueue = ({configRowsQuery, options}) ->
  configRowsQuery
  .returning('id')
  .then (configsRows) ->
    userRows = for row in configsRows
      do (row) -> {
        config_notifcation_id: row.id
        options
      }

    tables.user.notificationQueue()
    .insert(userRows)


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
  distribute
  enqueue
}
