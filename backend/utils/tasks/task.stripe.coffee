Promise = require "bluebird"
jobQueue = require '../util.jobQueue'
{HardFail} = require '../errors/util.error.jobQueue'
tables = require '../../config/tables'
logger = require('../../config/logger').spawn('task:stripe')
TaskImplementation = require './util.taskImplementation'
stripeErrorEnums = require '../../enums/enum.stripe.errors'

stripe = null
require('../../services/payment/stripe/service.payment.impl.stripe.bootstrap').then (s) -> stripe = s
{SubtaskHandler} = require './util.task.helpers'
stripeErrors  = require '../../utils/errors/util.errors.stripe'

###
  ratelimits: (RPS)
    liveMode: 100
    testMode: 30
###
#lower number to stay below rate limit, consider signups that are happening at the same time
NUM_ROWS_TO_PAGINATE = 25

findStripeErrors = (subtask) ->
  unless stripe
    logger.debug "stripe api is not ready in jobtask"
    return
  logger.debug "subtask findStripeErrors entered"
  logger.debug subtask, true

  tables.auth.toM_errors()
  .where 'error_name', 'ilike', '%stripe%'
  .where 'attempts', '<', 'max_attempts' #get active ones
  .orderBy 'id'
  .limit NUM_ROWS_TO_PAGINATE
  .then (queued) ->
    logger.debug "#{queued.length} stripe errors to fix."
    Promise.map queued, (row) ->

      enqueue = (subtaskName) ->
        jobQueue.queueSubsequentSubtask null, subtask, subtaskName, row, true

      switch row.error_name
        when stripeErrorEnums.stripeCustomerRemove
          enqueue 'stripe_removeErroredCustomers'
        when stripeErrorEnums.stripeCustomerBadCard
          enqueue 'stripe_removeBadCards'
        else
          throw new HardFail "Unsupported stripe error message"


###
 Example response of invalid/non-existant customer
 { [Error: No such customer: crap]
  type: 'StripeInvalidRequestError',
  rawType: 'invalid_request_error',
  code: undefined,
  param: 'id',
  message: 'No such customer: crap',
  detail: undefined,
  raw:
   { type: 'invalid_request_error',
     message: 'No such customer: crap',
     param: 'id',
     statusCode: 404,
     requestId: 'req_7poIYCVAQBggdP' },
  requestId: 'req_7poIYCVAQBggdP',
  statusCode: 404 } true
###
CommonSubtaskHandler = SubtaskHandler.compose

  errorHandler: stripeErrors.handler

  invalidRequestErrorType: stripeErrors.StripeInvalidRequestError.type

  removalService: (subtask) ->
    logger.debug "removing #{subtask.data.error_name} of id #{subtask.data.id} from error queue"
    tables.auth.toM_errors().where(id: subtask.data.id).del()

  updateService: (subtask) ->
    tables.auth.toM_errors()
    .update
      data: subtask.data
      attempt: subtask.data.attempt + 1
    .where id: subtask.data.id


RemoveErroredCustomersSubtaskHandler = SubtaskHandler.compose CommonSubtaskHandler,
  thirdPartyService: (subtask) ->
    stripe.customers.del subtask.data.customer
  invalidRequestRegex: /no such customer/i

RemoveBadCardsSubtaskHandler = SubtaskHandler.compose CommonSubtaskHandler,
  thirdPartyService: (subtask) ->
    stripe.customers.deleteCard subtask.data.customer, subtask.data.customerCard
  invalidRequestRegex: /no such source/i


subtasks =
  findStripeErrors: findStripeErrors
  removeErroredCustomers: RemoveErroredCustomersSubtaskHandler.handle
  removeBadCards: RemoveBadCardsSubtaskHandler.handle
  ###
  other tasks in theory
    - updatePlan
    - suspendCustomer
    - flagCustomer (potential suspension send out warning email)
  ###


module.exports = new TaskImplementation(subtasks)
