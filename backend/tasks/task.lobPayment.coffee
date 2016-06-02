Promise = require "bluebird"
jobQueue = require '../services/service.jobQueue'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
tables = require '../config/tables'
_ = require 'lodash'
TaskImplementation = require './util.taskImplementation'
logger = require('../config/logger').spawn('task:lobPayment')
moment = require 'moment'
{isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'
config = require '../config/config'

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

      tables.mail.letters()
      .select('id')
      .where('user_mail_campaign_id', campaign.id)
      .whereNotIn('status', ['sent', 'error-invalid'])

      .then (unsent) ->
        if unsent?.length
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

  payment = require('../services/services.payment')

  .then (payment) ->

    logger.debug "Checking whether #{campaign.label} is ready for billing"

    tables.mail.letters()
    .select(tables.mail.letters().raw "id, lob_response->'price' as price")
    .where(
      status: 'sent'
      user_mail_campaign_id: campaign.id
    )

    .then (letters) ->

      totalPrice = _.reduce (_.pluck letters, 'price'), (total, price) ->
        total + Number(price)

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

      tables.mail.campaign()
      .update
        status: 'paid'
        stripe_charge: stripeCharge
      .where
        id: campaign.id

subtasks =
  findCampaigns: findCampaigns
  chargeCampaign: chargeCampaign

module.exports = new TaskImplementation('lobPayment', subtasks)
