_ = require 'lodash'
Promise = require 'bluebird'
twilio = require 'twilio'
externalAccounts = require '../services/service.externalAccounts'
logger = require '../config/logger'
emailConfig = require '../config/email'
tables = require '../config/tables'
analyzeValue = require '../../common/utils/util.analyzeValue'


NO_CLIENT_THROW = 'no client'

twilioClientPromise = Promise.try () ->
  externalAccounts.getAccountInfo('twilio')
  .then (accountInfo) ->
    client: twilio(accountInfo.username, accountInfo.api_key)
    smsNumber: accountInfo.other.number
  .catch (err) ->
    # make sure we know there wasn't twilio info available
    logger.warn 'Twilio login not found in environment.'
    throw NO_CLIENT_THROW
twilioClientPromise.catch () -> # noop

getSmsOptions = (to, subject, number) ->
  to = '+1'+to if '+' not in to
  smsOptions =
    from: number
    to: to
    body: subject

getEmailOptions = (to, subject, message) ->
  to = [to] if not _.isArray(to)
  emailOptions =
    # from: NA    # default is the account used for making the SMTP transport
    to: to
    subject: subject
    text: message
    # html: <template>    # can leverage any html templating later if/when we need


notification = (type) ->
  (options) ->
    twilioClientPromise
    .then (twilioInfo) ->
      # query
      query = tables.config.notification()
      .select("user_id", "method", "email", "cell_phone")
      .innerJoin(tables.auth.user.tableName, "#{tables.config.notification.tableName}.user_id", "#{tables.auth.user.tableName}.id")
      .where
        type: type

      # restrict to a user_id if provided
      if options.user_id
        query = query.where
          user_id: options.user_id

      query
      .then (data) ->
        emailList = []

        # loop to build emailList as well as send sms
        # if notification lists grow large, we may need to refine this loop
        for datum in data
          do (datum) ->
            if datum.email and datum.method == 'email'
              emailList.push datum.email

            # sms currently required to send one by one; If we implement
            # an async or bulk method, we can handle it similar to email
            if datum.cell_phone and datum.method == 'sms'
              smsOptions = getSmsOptions(datum.cell_phone, options.subject, twilioInfo.smsNumber)
              twilioInfo.client.sendSms smsOptions, (error, info) ->
                if error
                  error = JSON.stringify error
                  logger.error "error sending SMS: #{error}\n#{info}"
        emailList
    .then (emailList) ->

      # set up full email message including error & info as needed
      msgContent = []
      if options.message
        msgContent.push options.message
        delete options.message

      # options.error flags whether to include the options data
      if options.error
        msgContent.push 'Details:'
        msgContent.push ("  #{k}: #{v}" for k, v of options).join '\n'
      message = msgContent.join '\n\n'

      # send email
      if emailList.length > 0
        emailOptions = getEmailOptions(emailList, "NOTIFICATION: #{options.subject}", message)
        emailConfig.getMailer (mailer) ->
          mailer.sendMail emailOptions, (error, info) ->
            if error
              error = JSON.stringify error
              logger.error "error sending EMAIL: #{error}\n#{info}"
    .catch (err) ->
      if err != NO_CLIENT_THROW
        logger.error "notification error: #{analyzeValue.getSimpleDetails(err)}"

    Promise.resolve()

module.exports =
  notification: notification
