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
{BasicEmailError, SmsError} = require '../utils/errors/util.error.notifcations'


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


sendBasicEmailNowPromise = ({emails, emailIds, options}) ->

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
  .catch (err) ->
    details = analyzeValue.getSimpleDetails(err)
    logger.error "notification error: #{details}"

    Promise.all emailIds.map (id) ->
      tables.user.notification()
      .insert {
        options
        config_notification_id: id
        error: details
        attempts: 1
      }


sendSmsNowPromise = ({datum, options}) ->
  twilioClientPromise
  .then (twilioInfo) ->
    sendSmsAsync = Promise.promisify twilioInfo.client.sendSms
    sendSmsAsync getSmsOptions(datum.cell_phone, options.subject, twilioInfo.smsNumber)
  .catch errorHelpers.isUnhandled, (err) ->
    throw new SmsError(err, 'Twilio Error. ')
  .catch (err) ->
    details = analyzeValue.getSimpleDetails(err)
    logger.error "notification error: #{details}"

    tables.user.notification()
    .insert {
      options
      config_notification_id: datum.id
      error: details
      attempts: 1
    }


module.exports = {
  twilioClientPromise
  getSmsOptions
  getEmailOptions
  buildBasicEmail
  sendBasicEmailNowPromise
  sendSmsNowPromise
}
