externalAccounts = require './service.externalAccounts'
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
awsService = require('./service.aws')
paymentSvc = null

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

#
# Retrieve API keys from external accounts (once)
#  The test API is always available for price quotes / previews
#  The live API is only initialized if the environment is configured as follows:
#    - MAILING_PLATFORM.LIVE_MODE is on
#    - Either environment is production, or ALLOW_LIVE_APIS is on
#    - Note that even if both of these things are true, the API key in the database ultimately determines how 'live' behaves
#
_apiPromise = null
lobPromise = () ->

  # This class definition is here so it is easier to rewire
  class LobAPI extends LobFactory
    constructor: ({@apiKey, @apiName}) ->
      logger.debug "Initialized LOB API-#{@apiName}"
      super(@apiKey)

    getLetter: (letterId) ->
      logger.debug "API-#{@apiName} getLetter #{letterId}"
      @letters.retrieve letterId
      .catch @handleError.bind(@)

    listLetters: (opts) ->
      logger.debug "API-#{@apiName} listLetters opts: #{opts}"
      @letters.list opts
      .catch @handleError.bind(@)

    sendLetter: (letter) ->
      logger.debug "API-#{@apiName} sendLetter #{letter.metadata?.uuid}"
      @letters.create letter
      .catch @handleError.bind(@)

    handleError: (err) ->
      lobError = new Error(err.message)
      msg = "LOB-#{@apiName} API responded #{err.status_code}"
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

  # Get account info
  if _apiPromise
    logger.debug 'Returning cached promise'
    _apiPromise
  else
    _apiPromise = externalAccounts.getAccountInfo('lob')
      .then (accountInfo) ->
        # The test API is always needed for price quotes and previews
        apis = test: new LobAPI(apiKey: accountInfo.other.test_api_key, apiName: 'test')

        # Depending on environment settings, mail is sent using either the live or test API
        if config.MAILING_PLATFORM.LIVE_MODE
          if config.ENV != 'production' && !config.ALLOW_LIVE_APIS
            throw new Error("Refusing to use LOB-live API from #{config.ENV} -- set ALLOW_LIVE_APIS to force")
          apis.live = new LobAPI(apiKey: accountInfo.api_key, apiName: 'live')
        else
          apis.live = apis.test

        apis

#
# Create letter for outgoing mail table. sendLetter() expects object with this structure
#
buildLetter = (campaign, recipient) ->

  getAddress = (r) ->
    name: (r.name ? "#{r.first_name ? ''} #{r.last_name ? ''}".trim()) || 'Homeowner'
    address_line1: r.address_line1 ? "#{r.street_address_num ? ''} #{r.street_address_name ? ''}"
    address_line2: r.address_line2 ? r.street_address_unit ? ''
    address_city: r.address_city ? r.city ? ''
    address_state: r.address_state ? r.state ? ''
    address_zip: r.address_zip ? r.zip ? ''

  address_to = getAddress recipient
  address_from = getAddress campaign.sender_info

  letter =
    auth_user_id: campaign.auth_user_id
    user_mail_campaign_id: campaign.id
    address_to: address_to
    address_from: address_from
    file: campaign.lob_content
    status: 'ready'
    rm_property_id: recipient.rm_property_id
    options:
      aws_key: campaign.aws_key
      color: campaign.options?.color? or false
      metadata:
        campaignId: campaign.id
        userId: campaign.auth_user_id
        recipientType: recipient.type
        uuid: uuid.v1() # important for retries
      data: # These may act as placeholders in HTML content
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


################
# Public methods
################

#
# Retrieves LOB letter object by id
#  https://lob.com/docs#letters_retrieve
#
getLetter = (lobId, apiName = 'live') ->
  lobPromise()
  .then (lob) ->
    lob[apiName].getLetter lobId

#
# Sends letter to the LOB test API to figure out the total cost and get a preview url for the letter
#
getPriceQuote = (userId, campaignId) ->
  tables.mail.campaign()
    .select('id', 'auth_user_id', 'name', 'lob_content', 'aws_key', 'status', 'sender_info', 'recipients', 'options')
    .where(id: campaignId, auth_user_id: userId)

  .then ([campaign]) ->
    throw new Error("recipients must be an array") unless _.isArray campaign?.recipients

    result = null
    Promise.each campaign.recipients, (r) ->
      address = "#{r.street_address_num} #{r.street_address_name} #{r.city} #{r.state} #{r.zip}"
      logger.debug "Checking #{address}"
      letter = buildLetter campaign, r
      sendLetter letter, 'test'
      .then (lobResponse) ->
        logger.debug "Address was valid: #{address}"
        result =
          pdf: lobResponse.url
          price: lobResponse.price * campaign.recipients.length
          lobResponse: lobResponse
        throw "Stop checking addresses" # no need to check more addresses
      .catch LobErrors.LobBadRequestError, -> # this address was bad, check the next one
        logger.debug "Invalid address: #{address}. Trying next recipient"
    .catch ->
      result # Probably got a valid address
    .then ->
      if result
        return result
      else
        throw new Error("No valid addresses were found")

# Retrieves LOB letters by metadata
#  https://lob.com/docs#letters_retrieve
#
listLetters = (opts, apiName = 'live') ->
  lobPromise()
  .then (lob) ->
    lob[apiName].listLetters opts

#
# Sets appropriate LOB options depending on whether letter is HTML or PDF and sends it
#  https://lob.com/docs#letters_create
#
# The apiName must explicitly passed by caller. This is aimed to avoid mistakenly using live in the wrong place.
#
sendLetter = (letter, apiName) ->
  if !apiName
    throw new Error("apiName is required")

  lobPromise()
  .then (lob) ->
    Promise.try ->
      # assign a temporary signed url for the campaign pdf we host in s3
      if letter.options.aws_key
        # 10 minute expiration for url below
        awsService.getTimedDownloadUrl
          extAcctName: awsService.buckets.PDF
          Key: letter.options.aws_key
        .then (file) ->
          letter.file = file
          letter.options.template = false
      else
        letter.options.template = true
        letter.options.color = false

    .catch (err) ->
      throw new Error(err, "Could not acquire a signed url.")

    .then ->
      letter = _.merge letter, letter.options
      letter.data = _.pick letter.data, (v) -> v # empty values are disallowed
      letter.to = letter.address_to
      letter.from = letter.address_from
      letter = _.pick letter, LOB_LETTER_FIELDS

      lob[apiName].sendLetter letter

#
# Creates a CC hold for the mail campaign and places letters in the outgoing mail table
#  https://stripe.com/docs/api#create_charge
#
sendCampaign = (campaignId, userId) ->
  logger.debug "Sending campaign #{campaignId}"
  Promise.props({

    authUser: tables.auth.user()
      .select('stripe_customer_id')
      .where(id: userId)

    campaign: tables.mail.campaign()
      .select('id', 'auth_user_id', 'name', 'lob_content', 'aws_key', 'status', 'sender_info', 'recipients', 'options')
      .where(id: campaignId, auth_user_id: userId)

    payment: paymentSvc or require('./services.payment') # allows rewire

    lob: lobPromise()
  })

  .catch isUnhandled, (err) ->

    throw new PartiallyHandledError(err, "Campaign cannot be sent right now -- try again later")

  .then ({authUser, campaign, payment, lob}) ->

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
      getPriceQuote userId, campaign.id

      .catch isUnhandled, (err) ->

        throw new PartiallyHandledError(err, "Could not get price quote for campaign #{campaign.id}")

      .then ({price}) ->

        dbs.transaction 'main', (tx) ->

          logger.debug "Creating $#{price.toFixed(2)} CC hold on default card for customer #{stripe_customer_id}"

          payment.customers.charge
            customer: stripe_customer_id
            source: stripeCustomer.default_source
            amount: price
            capture: false # funds held but not actually charged until letters are sent to LOB
            description: "Mail Campaign \"#{campaign.name}\"" # Included in reciept emails
            ,
            "charge_campaign_#{campaign.id}" # unique identifier to prevent duplicate charges

          .catch isUnhandled, (err) ->

            throw new PartiallyHandledError(err, "CC hold failed for customer #{stripe_customer_id}")

          .then (stripeCharge) ->

            # Whether or not mailing API is turned on, only queue real letters if payment is live
            apiName = if config.PAYMENT_PLATFORM.LIVE_MODE then lob.live.apiName else lob.test.apiName

            logger.debug "Queueing #{campaign.recipients.length} letters for campaign #{campaignId} using API #{apiName}"
            logger.debug -> "#{JSON.stringify stripeCharge}"

            tables.mail.letters(transaction: tx)
            .insert _.map campaign.recipients, (recipient) ->
              letter = buildLetter campaign, recipient
              letter.lob_api = apiName
              letter

            .catch isUnhandled, (err) ->

              throw new PartiallyHandledError(err, "Failed to queue #{campaign.recipients.length} letters for campaign #{campaignId}")

            .then (inserted) ->

              logger.debug "Queued #{campaign.recipients.length} letters, changing status of campaign #{campaignId} -> 'sending'"
              tables.mail.campaign(transaction: tx)
              .update(status: 'sending', stripe_charge: stripeCharge)
              .where(id: campaignId, auth_user_id: userId)

            .catch isUnhandled, (err) ->

              throw new PartiallyHandledError(err, "Failed to update campaign #{campaignId}")

module.exports =
  getLetter: getLetter
  getPriceQuote: getPriceQuote
  listLetters: listLetters
  sendLetter: sendLetter
  sendCampaign: sendCampaign
