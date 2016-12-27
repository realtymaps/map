Promise = require "bluebird"
jobQueue = require '../services/service.jobQueue'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
tables = require '../config/tables'
TaskImplementation = require './util.taskImplementation'
logger = require('../config/logger').spawn('task:lobPayment')
moment = require 'moment'
{isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
config = require '../config/config'
dbs = require '../config/dbs'

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
      'name'
      'stripe_charge'
      'price_per_letter'
    ]
  )
  .where status: 'sending'

  .then (campaigns) ->

    logger.info "Checking #{campaigns.length} campaigns for billing status"

    Promise.map campaigns, (campaign) ->

      campaign.label = "campaign '#{campaign.name}' (id #{campaign.id})"

      readyDate = moment(campaign.stripe_charge.created, 'X').add(config.MAILING_PLATFORM.CAMPAIGN_BILLING_DELAY_DAYS, 'days')
      if not readyDate.isBefore(moment())
        logger.debug "#{campaign.label} will be ignored until #{readyDate.format()}"
        return

      forceCaptureDate = moment(campaign.stripe_charge.created, 'X').add(config.MAILING_PLATFORM.CAMPAIGN_BILLING_CAPTURE_DAYS, 'days')
      if forceCaptureDate.isBefore(moment())
        logger.debug "#{campaign.label} has been sending too long, capturing NOW"

      tables.mail.letters()
      .select('id')
      .where('user_mail_campaign_id', campaign.id)
      .whereIn('status', ['ready', 'error-transient'])

      .then (unsent) ->
        if unsent?.length && forceCaptureDate.isAfter(moment())
          logger.debug "#{campaign.label} still has #{unsent.length} unsent letters and/or errors - skipping billing for now"
          return
        else
          if campaign.stripe_charge?.livemode && !config.PAYMENT_PLATFORM.LIVE_MODE
            logger.info "#{campaign.label} original payment was live mode but payments not currently live - skipping"
            return
          if !campaign.stripe_charge?.livemode && config.PAYMENT_PLATFORM.LIVE_MODE
            logger.info "#{campaign.label} original payment was test mode but payments are currently live - skipping"
            return

          jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: 'chargeCampaign', manualData: campaign, replace: true})

#
# This task finalizes the charges for a campaign that has finished sending
#
chargeCampaign = (subtask) ->
  campaign = subtask.data

  require('../services/payment/stripe')()
  .then (payment) ->

    logger.debug "Checking whether #{campaign.label} is ready for billing"

    tables.mail.letters()
    .count('id')
    .where(
      status: 'sent'
      user_mail_campaign_id: campaign.id
    )

    .then ([result]) ->
      try
        totalPrice = Number(campaign.price_per_letter * result.count)
      catch err
        throw new SoftFail(err, "Expected a price per letter for #{campaign.label}, but got #{campaign.price_per_letter} for #{result.count} sent letters.")
      logger.debug "Attempting to capture $#{totalPrice} (original charge $#{campaign.stripe_charge.amount/100}) for #{campaign.label}"

      # Shown on CC statements (all caps, 22-character limit)
      statement_descriptor = "REALTYMAPS #{campaign.stripe_charge.description ? ''}".trim().slice 0, 22

      payment.customers.capture
        charge: campaign.stripe_charge.id
        amount: totalPrice
        statement_descriptor: statement_descriptor

    .catch isUnhandled, (err) ->

      throw new SoftFail(err, "Failed to capture charge for #{campaign.label}")

    .then (stripeCharge) ->

      logger.info "Captured #{stripeCharge.amount/100} for #{campaign.label}"

      dbs.transaction (transaction) ->
        tables.mail.campaign({transaction})
        .update
          status: 'paid'
          stripe_charge: stripeCharge
        .where
          id: campaign.id
        .then () ->
          tables.mail.letters({transaction})
          .update(status: 'error-cancelled')
          .where('user_mail_campaign_id', campaign.id)
          .whereIn('status', ['error-transient', 'ready'])


subtasks =
  findCampaigns: findCampaigns
  chargeCampaign: chargeCampaign

module.exports = new TaskImplementation('lobPayment', subtasks)
