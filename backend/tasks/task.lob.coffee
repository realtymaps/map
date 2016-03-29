Promise = require "bluebird"
jobQueue = require '../utils/util.jobQueue'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
tables = require '../config/tables'
logger = require '../config/logger'
_ = require 'lodash'
TaskImplementation = require './util.taskImplementation'
lobSvc = require '../services/service.lob'
LobErrors = require '../utils/errors/util.errors.lob'
{isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
logger = require('../config/logger').spawn('task:lob')
{safeJsonArray} = require '../utils/util.sql.helpers'
moment = require 'moment'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'

CAMPAIGN_BILLING_DELAY = 1

#
# This task find letters that have been queued from a mail campaign
#
findLetters = (subtask) ->
  tables.mail.letters()
  .select(
    [
      'id'
      'address_to'
      'address_from'
      'file'
      'options'
      'retries',
      'lob_errors',
      'lob_api'
    ]
  )
  .whereIn('status', [ 'ready', 'error-transient' ])
  .then (letters) ->
    Promise.map letters, (letter) ->
      jobQueue.queueSubsequentSubtask null, subtask, 'lob_createLetter', letter, true

#
# This task sends a _single_ letter via the LOB API and saves the response data (or error) returned
#   https://lob.com/docs#letters_create)
#
createLetter = (subtask) ->
  letter = subtask.data

  lob_errors = []
  if letter.lob_errors?
    lob_errors = lob_errors.concat letter.lob_errors

  lobSvc.sendLetter letter, letter.lob_api

  .then (lobResponse) ->
    logger.debug -> "#{JSON.stringify lobResponse, null, 2}"
    tables.mail.letters()
    .update
      lob_response: lobResponse
      status: 'sent'
      retries: letter.retries + 1
    .where
      id: letter.id

  .catch LobErrors.LobRateLimitError, (error) ->
    tables.mail.letters()
    .update
      lob_errors: safeJsonArray lob_errors.concat error.message
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id

    throw new HardFail(error, "Lob API rate limit exceeded")

  .catch LobErrors.LobUnauthorizedError, (error) ->
    tables.mail.letters()
    .update
      lob_errors: safeJsonArray lob_errors.concat error.message
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id

    throw new HardFail(error, "Lob API access denied - check configuration/keys")

  .catch LobErrors.LobForbiddenError, (error) ->
    tables.mail.letters()
    .update
      lob_errors: safeJsonArray lob_errors.concat error.message
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id

    throw new HardFail(error, "Lob API access denied - check configuration/keys")

  .catch LobErrors.LobBadRequestError, (error) ->
    tables.mail.letters()
    .update
      lob_errors: safeJsonArray lob_errors.concat error.message
      status: 'error-invalid'
      retries: letter.retries + 1
    .where
      id: letter.id

    # Do not throw in this case, since the address is probably undeliverable

  .catch LobErrors.LobServerError, (error) ->
    tables.mail.letters()
    .update
      lob_errors: safeJsonArray lob_errors.concat error.message
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id

    throw new SoftFail(error, "Lob API server error - retry later")

  .catch (error) ->
    logger.error "Unknown error sending LOB letter!"
    throw error

#
# This task finds campaigns that are ready for final billing
#   The charge will not be captured before the day after the charge was initiated
#
findCampaigns = (subtask) ->
  tables.mail.campaign()
  .select(
    [
      'id'
      'status'
      'stripe_charge'
    ]
  )
  .where status: 'sending'

  .then (campaigns) ->

    logger.info "Checking #{campaigns.length} campaigns for billing status"

    Promise.map campaigns, (campaign) ->

      readyDate = moment(campaign.stripe_charge.created, 'X').add(CAMPAIGN_BILLING_DELAY, 'days')
      if not readyDate.isBefore(moment())
        logger.debug "Campaign #{campaign.id} will be ignored until #{readyDate.format()}"
        return

      tables.mail.letters()
      .select('id')
      .where('user_mail_campaign_id', campaign.id)
      .whereNotIn('status', ['sent', 'error-invalid'])

      .then (unsent) ->
        if unsent?.length
          logger.debug "Campaign #{campaign.id} still has #{unsent.length} unsent letters and/or errors - skipping billing for now"
          return
        else
          jobQueue.queueSubsequentSubtask null, subtask, 'lob_chargeCampaign', campaign, true

#
# This task finalizes the charges for a campaign that has finished sending
#
chargeCampaign = (subtask) ->
  campaign = subtask.data

  payment = require('../services/services.payment')

  .then (payment) ->

    logger.debug -> "#{JSON.stringify campaign}"

    tables.mail.letters()
    .select(tables.mail.letters().raw "id, lob_response->'price' as price")
    .where(
      status: 'sent'
      user_mail_campaign_id: campaign.id
    )

    .then (letters) ->

      totalPrice = _.reduce (_.pluck letters, 'price'), (total, price) ->
        total + Number(price)

      logger.debug "Attempting to capture $#{totalPrice} (original charge $#{campaign.stripe_charge.amount/100}) for campaign #{campaign.id}"

       # Shown on CC statements (all caps, 22-character limit)
      statement_descriptor = "REALTYMAPS #{campaign.stripe_charge.description ? ''}".trim().slice 0, 22

      payment.customers.capture
        charge: campaign.stripe_charge.id
        amount: totalPrice
        statement_descriptor: statement_descriptor

    .catch isUnhandled, (err) ->

      throw new SoftFail(err, "Failed to capture charge for campaign #{campaign.id}")

    .then (stripeCharge) ->

      logger.debug "Captured #{stripeCharge.amount/100} for campaign #{campaign.id}"

      tables.mail.campaign()
      .update
        status: 'paid'
        stripe_charge: stripeCharge
      .where
        id: campaign.id

subtasks =
  findLetters: findLetters
  createLetter: createLetter
  findCampaigns: findCampaigns
  chargeCampaign: chargeCampaign

module.exports = new TaskImplementation(subtasks)
