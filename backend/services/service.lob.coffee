externalAccounts = require '../services/service.externalAccounts'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
logger = require('../config/logger').spawn('service:lob')
_ = require 'lodash'
config = require '../config/config'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
tables = require '../config/tables'
LobErrors = require '../utils/errors/util.errors.lob.coffee'
logger = require('../config/logger').spawn('service:lob')
dbs = require('../config/dbs')
uuid = require 'node-uuid'
paymentSvc = null

LOB_LETTER_DEFAULTS =
  color: true
  template: false

LOB_LETTER_FIELDS = [
   'to'
   'from'
   'color'
   'file'
   'data'
   'double_sided'
   'template'
   'extra_service'
   'return_envelope'
   'perforated_page'
   'metadata'
]

handleError = (env) -> (err) ->
  lobError = new Error(err.message)
  msg = "LOB-#{env} API responded #{err.status_code}"
  if err.status_code == 401
    throw new LobErrors.LobUnauthorizedError(lobError, msg)
  else if err.status_code == 403
    throw new LobErrors.LobForbiddenError(lobError, msg)
  else if err.status_code == 404
    throw new LobErrors.LobNotFoundError(lobError, msg)
  else if err.status_code == 422
    throw new LobErrors.LobBadRequestError(lobError, msg)
  else if err.status_code == 429
    throw new LobErrors.LobRateLimitError(lobError, msg)
  else if err.status_code == 500
    throw new LobErrors.LobServerError(lobError, msg)

lobPromise = () ->
  externalAccounts.getAccountInfo('lob')
  .then (accountInfo) ->
    test = new LobFactory(accountInfo.other.test_api_key)
    test.rm_type = 'test'
    promisify.lob(test)
    live = new LobFactory(accountInfo.api_key)
    live.rm_type = 'live'
    promisify.lob(live)
    { test, live }

_getAddress = (r) ->
  name: (r.name ? "#{r.first_name ? ''} #{r.last_name ? ''}".trim()) || 'Homeowner'
  address_line1: r.address_line1 ? "#{r.street_address_num ? ''} #{r.street_address_name ? ''}"
  address_line2: r.address_line2 ? r.street_address_unit ? ''
  address_city: r.address_city ? r.city ? ''
  address_state: r.address_state ? r.state ? ''
  address_zip: r.address_zip ? r.zip ? ''

createLetter = (letter) ->
  lobPromise()
  .then (lob) ->
    _.defaultsDeep letter, LOB_LETTER_DEFAULTS

    letter.data = _.pick letter.data, (v) -> v # empty values are disallowed

    if config.ENV != 'production'
      throw new Error("Refusing to use LOB-live API from #{config.ENV}")

    logger.debug -> "createLetter() #{JSON.stringify letter, null, 2}"
    lob.live.letters.create _.pick letter, LOB_LETTER_FIELDS

    .catch isUnhandled, handleError('live')

createLetterTest = (letter) ->
  lobPromise()
  .then (lob) ->
    _.defaultsDeep letter, LOB_LETTER_DEFAULTS

    letter.data = _.pick letter.data, (v) -> v # empty values are disallowed

    logger.debug () -> "createLetterTest() #{JSON.stringify letter, null, 2}"
    lob.test.letters.create _.pick(letter, LOB_LETTER_FIELDS)

    .catch isUnhandled, handleError('test')

sendCampaign = (campaignId, userId) ->

  logger.debug "Sending campaign #{campaignId}"

  Promise.props({

    authUser: tables.auth.user()
      .select('stripe_customer_id')
      .where(id: userId)

    campaign: tables.mail.campaign()
      .select('id', 'auth_user_id', 'name', 'content', 'status', 'sender_info', 'recipients')
      .where(id: campaignId, auth_user_id: userId)

    payment: paymentSvc or require('./services.payment')

  })

  .catch isUnhandled, (err) ->

    throw new PartiallyHandledError(err, "Campaign cannot be sent right now -- try again later")

  .then ({authUser, campaign, payment}) ->

    [authUser] = authUser
    [campaign] = campaign
    {stripe_customer_id} = authUser

    if not campaign
      throw new PartiallyHandledError("Campaign #{campaignId} not found")

    if campaign.status != 'ready'
      throw new PartiallyHandledError("Campaign #{campaignId} has status '#{campaign.status}' -- cannot send unless status is 'ready'")

    if not _.isArray campaign?.recipients
      throw new PartiallyHandledError("Campaign #{campaignId} has invalid recipients")

    logger.debug -> "Retrieving customer #{stripe_customer_id} for user #{userId} #{JSON.stringify authUser}"
    payment.customers.get authUser

    .catch isUnhandled, (err) ->

      throw new PartiallyHandledError(err, "Could not find stripe customer #{stripe_customer_id} for user #{userId}")

    .then (stripeCustomer) ->

      logger.debug "Checking price to send campaign #{campaign.id} on behalf of user #{userId}"
      getPriceQuote userId,
        file: campaign.content
        from: _getAddress campaign.sender_info
        recipients: campaign.recipients.slice 0, 1

      .catch isUnhandled, (err) ->

        throw new PartiallyHandledError(err, "Could not get price quote for campaign #{campaign.id}")

      .then (pricePerLetter) ->

        dbs.transaction 'main', (tx) ->

          amount = pricePerLetter * campaign.recipients.length
          logger.debug "Creating $#{amount.toFixed(2)} CC hold on default card for customer #{stripe_customer_id}"

          payment.customers.charge
            customer: stripe_customer_id
            source: stripeCustomer.default_source
            amount: amount
            capture: false # funds held but not actually charged until letters are sent to LOB
            description: "Mail Campaign \"#{campaign.name}\"" # Included in reciept emails
            ,
            "charge_campaign_#{campaign.id}" # unique identifier to prevent duplicate charges

          .catch isUnhandled, (err) ->

            throw new PartiallyHandledError(err, "CC hold failed for customer #{stripe_customer_id}")

          .then (stripeCharge) ->

            logger.debug "Queueing #{campaign.recipients.length} letters for campaign #{campaignId}"
            logger.debug -> "#{JSON.stringify stripeCharge}"
            queueLetters(campaign, tx)

            .catch isUnhandled, (err) ->

              throw new PartiallyHandledError(err, "Failed to queue #{campaign.recipients.length} letters for campaign #{campaignId}")

            .then (inserted) ->

              logger.debug "Queued #{campaign.recipients.length} letters, changing status of campaign #{campaignId} -> 'sending'"
              tables.mail.campaign(tx)
              .update(status: 'sending', stripe_charge: stripeCharge)
              .where(id: campaignId, auth_user_id: userId)

            .catch isUnhandled, (err) ->

              throw new PartiallyHandledError(err, "Failed to update campaign #{campaignId}")

queueLetters = (campaign, tx) ->
  tables.mail.letters(tx)
  .insert _.map campaign.recipients, (recipient) ->
    address_to = _getAddress recipient
    address_from = _getAddress campaign.sender_info

    auth_user_id: campaign.auth_user_id
    user_mail_campaign_id: campaign.id
    address_to: address_to
    address_from: address_from
    file: campaign.content
    status: 'ready'
    options:
      metadata:
        campaignId: campaign.id
        userId: campaign.auth_user_id
        uuid: uuid.v1()
      data:
        campaign_name: campaign.name
        recipient_name: address_to.name
        recipient_address_line1: address_to.address_line1
        recipient_address_line2: address_to.address_line2
        recipient_city: address_to.address_city
        recipient_state: address_to.address_state
        recipient_zip: address_to.address_zip
        sender_name: address_from.name
        sender_address_line1: address_from.address_line1
        sender_address_line2: address_from.address_line2
        sender_city: address_from.address_city
        sender_state: address_from.address_state
        sender_zip: address_from.address_zip

getPriceQuote = (userId, data) ->
  lobPromise()
  .then (lob) ->
    throw new Error("recipients must be an array") unless _.isArray data?.recipients
    Promise.map data.recipients, (recipient) ->
      letter = _.clone data
      letter.to = _getAddress recipient
      createLetterTest letter
  .then (lobResponses) ->
    _.reduce (_.pluck lobResponses, 'price'), (total, price) ->
      total + Number(price)

module.exports =
  getPriceQuote: getPriceQuote
  createLetter: createLetter
  createLetterTest: createLetterTest
  sendCampaign: sendCampaign
