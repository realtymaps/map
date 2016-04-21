Promise = require "bluebird"
jobQueue = require '../services/service.jobQueue'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
tables = require '../config/tables'
logger = require '../config/logger'
_ = require 'lodash'
TaskImplementation = require './util.taskImplementation'
lobSvc = require '../services/service.lob'
LobErrors = require '../utils/errors/util.errors.lob'
logger = require('../config/logger').spawn('task:lob')
{safeJsonArray} = require '../utils/util.sql.helpers'
moment = require 'moment'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
config = require '../config/config'

#
# This task find letters that have been queued from a mail campaign
#
findLetters = (subtask) ->
  Promise.map ['test', 'live'], (apiName) ->
    query = tables.mail.letters()
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
      .where('status', 'ready')
      .where('lob_api', apiName)

    if apiName == 'test'
      query.limit(5)

    query.then (letters) ->
      Promise.map letters, (letter) ->
        jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: 'createLetter', manualData: letter, replace: true})

#
# This task sends a _single_ letter via the LOB API and saves the response data (or error) returned
#   https://lob.com/docs#letters_create)
#
createLetter = (subtask) ->
  letter = subtask.data

  uuid = letter?.options?.metadata?.uuid

  if !uuid
    logger.debug "Letter #{letter.id} has no uuid! Marking invalid"
    return tables.mail.letters()
    .update
      status: 'error-invalid'
    .where
      id: letter.id

  lob_errors = []
  if letter.lob_errors?
    lob_errors = lob_errors.concat letter.lob_errors

  # Check existence
  lobSvc.listLetters
    date_created:
      gte: letter.created_date
    metadata:
      uuid: uuid
   ,
    letter.lob_api

  .then ({data}) ->
    if data.length > 0
      logger.info "Letter #{uuid} already exists - unexpected"
      return tables.mail.letters()
      .update
        lob_response: data[0]
        status: 'error-transient'
      .where
        id: letter.id

    logger.debug "Sending letter #{letter.id}"
    return lobSvc.sendLetter letter, letter.lob_api

    .catch isUnhandled, (error) ->
      tables.mail.letters()
      .update
        lob_errors: safeJsonArray lob_errors.concat error.message
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id
      .then ->
        throw new SoftFail(error)

    .catch LobErrors.LobRateLimitError, (error) ->
      tables.mail.letters()
      .update
        lob_errors: safeJsonArray lob_errors.concat error.message
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id
      .then ->
        throw new HardFail(error, "Lob API rate limit exceeded")

    .catch LobErrors.LobUnauthorizedError, (error) ->
      tables.mail.letters()
      .update
        lob_errors: safeJsonArray lob_errors.concat error.message
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id
      .then ->
        throw new HardFail(error, "Lob API access denied - check configuration/keys")

    .catch LobErrors.LobForbiddenError, (error) ->
      tables.mail.letters()
      .update
        lob_errors: safeJsonArray lob_errors.concat error.message
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id
      .then ->
        throw new HardFail(error, "Lob API forbidden - check configuration/keys")

    .catch LobErrors.LobBadRequestError, (error) ->
      tables.mail.letters()
      .update
        lob_errors: safeJsonArray lob_errors.concat error.message
        status: 'error-invalid'
        retries: letter.retries + 1
      .where
        id: letter.id
      .then ->
        return # Do not throw in this case, since the address is probably undeliverable

    .catch LobErrors.LobServerError, (error) ->
      tables.mail.letters()
      .update
        lob_errors: safeJsonArray lob_errors.concat error.message
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id
      .then ->
        throw new SoftFail(error, "Lob API server error - retry later")

    .then (lobResponse) ->
      logger.debug -> "Sent letter #{lobResponse.id}"
      tables.mail.letters()
      .update
        lob_response: lobResponse
        status: 'sent'
        retries: letter.retries + 1
      .where
        id: letter.id

    .catch isUnhandled, (error) ->
      throw new HardFail(error, "Error updating letter #{letter.id}!")

subtasks =
  findLetters: findLetters
  createLetter: createLetter

module.exports = new TaskImplementation(subtasks)
