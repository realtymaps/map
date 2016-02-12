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

LOB_LETTER_DEFAULTS =
  color: true
  template: true

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

lobPromise = Promise.try () ->
  externalAccounts.getAccountInfo('lob')
  .then (accountInfo) ->
    test = new LobFactory(accountInfo.other.test_api_key)
    test.rm_type = 'test'
    promisify.lob(test)
    live = new LobFactory(accountInfo.api_key)
    live.rm_type = 'live'
    promisify.lob(live)
    { test, live }

handleError = (env) -> (err) ->
  lobError = new Error(err.message)
  msg = "LOB-#{env} API responded #{err.status_code}"
  if err.status_code == 401
    throw new LobErrors.LobUnauthorizedError(lobError, msg)
  else if err.status_code = 403
    throw new LobErrors.LobForbiddenError(lobError, msg)
  else if err.status_code = 404
    throw new LobErrors.LobNotFoundError(lobError, msg)
  else if err.status_code = 422
    throw new LobErrors.LobBadRequestError(lobError, msg)
  else if err.status_code = 429
    throw new LobErrors.LobRateLimitError(lobError, msg)
  else if err.status_code = 500
    throw new LobErrors.LobServerError(lobError, msg)

_getAddress = (r) ->
  name: r.name ? "#{r.first_name ? ''} #{r.last_name ? ''}".trim()
  address_line1: r.address_line1 ? "#{r.street_address_num ? ''} #{r.street_address_name ? ''}"
  address_line2: r.address_line2 ? r.street_address_unit ? ''
  address_city: r.address_city ? r.city ? ''
  address_state: r.address_state ? r.state ? ''
  address_zip: r.address_zip ? r.zip ? ''

createLetter = (letter) ->
  lobPromise
  .then (lob) ->
    _.defaultsDeep letter, LOB_LETTER_DEFAULTS

    if config.ENV != 'production'
      throw new Error("Refusing to use LOB-live API from #{config.ENV}")

    logger.debug -> "createLetter() #{JSON.stringify letter, null, 2}"
    lob.live.letters.createAsync _.pick letter, LOB_LETTER_FIELDS

    .catch isUnhandled, handleError('test')

createLetterTest = (letter) ->
  lobPromise
  .then (lob) ->
    _.defaultsDeep letter, LOB_LETTER_DEFAULTS

    logger.debug () -> "createLetterTest() #{JSON.stringify letter, null, 2}"
    lob.test.letters.createAsync _.pick letter, LOB_LETTER_FIELDS

    .catch isUnhandled, handleError('live')

sendCampaign = (campaignId, userId) ->

  dbs.get('main').transaction (tx) ->
    tables.mail.campaign(tx)
    .select('id', 'auth_user_id', 'name', 'content', 'status', 'sender_info', 'recipients')
    .where(id: campaignId, auth_user_id: userId)
    .then ([campaign]) ->
      if not campaign
        throw new Error("campaign #{campaignId} not found")

      if campaign.status != 'ready'
        throw new Error("campaign #{campaignId} has status '#{campaign.status}' -- cannot send unless status is 'ready'")

      if not _.isArray campaign?.recipients
        throw new Error("campaign #{campaignId} has invalid recipients")

      logger.debug "Creating #{campaign.recipients.length} letters for campaign #{campaignId}"

      tables.mail.letters(tx)
      .insert _.map campaign.recipients, (recipient) ->
        address_to = _getAddress recipient
        address_from = _getAddress campaign.sender_info

        auth_user_id: userId
        user_mail_campaign_id: campaignId
        address_to: address_to
        address_from: address_from
        file: campaign.content
        status: 'ready'
        description: campaign.name
        options:
          metadata: { campaignId, userId, uuid: uuid.v1() }
          data:
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

      .catch isUnhandled, (err) ->
        throw new PartiallyHandledError(err, "failed to create letters for campaign #{campaignId}")

      tables.mail.campaign(tx)
      .update(status: 'sending')
      .where(id: campaignId, auth_user_id: userId)
      .catch isUnhandled, (err) ->
        throw new PartiallyHandledError(err, "failed to set status for campaign #{campaignId}")

getPriceQuote = (userId, data) ->
  lobPromise
  .then (lob) ->
    throw new Error("recipients must be an array") unless _.isArray data?.recipients
    Promise.map data.recipients, (recipient) ->
      letter = _.clone data
      letter.to = recipient
      createLetterTest letter
  .then (lobResponses) ->
    _.reduce (_.pluck lobResponses, 'price'), (total, price) ->
      total + Number(price)

module.exports =
  getPriceQuote: getPriceQuote
  createLetter: createLetter
  createLetterTest: createLetterTest
  sendCampaign: sendCampaign
