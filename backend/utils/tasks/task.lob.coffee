Promise = require "bluebird"
jobQueue = require '../util.jobQueue'
{SoftFail, HardFail} = require '../errors/util.error.jobQueue'
tables = require '../../config/tables'
logger = require '../../config/logger'
_ = require 'lodash'
TaskImplementation = require './util.taskImplementation'
lobSvc = require '../../services/service.lob'
LobErrors = require '../errors/util.errors.lob'
{isCausedBy} = require '../errors/util.error.partiallyHandledError'
logger = require('../../config/logger').spawn('task:lob')

#
# This task find letters that have been queued from a mail campaign
#
findLetters = (subtask) ->
  tables.mail.letters()
  .select(
    [
      'id'
      'address_to as to'
      'address_from as from'
      'file'
      'options'
      'retries',
      'lob_errors'
    ]
  )
  .where(
    status: 'ready'
  )
  .then (letters) ->
    Promise.map letters, (letter) ->
      letterRequest = _.merge letter, letter.options
      jobQueue.queueSubsequentSubtask null, subtask, 'lob_createLetter', letterRequest, true

#
# This task sends a _single_ letter via the LOB API and saves the response data (or error) returned
#   https://lob.com/docs#letters_create)
#
sendLetter = (subtask) ->
  letter = subtask.data

  lob_errors = []
  if letter.lob_errors?
    lob_errors = lob_errors.concat letter.lob_errors

  lobSvc.createLetterTest letter

  .catch isCausedBy(LobErrors.LobRateLimitError), (error) ->
    tables.mail.letters()
    .update
      lob_errors: lob_errors.concat error
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id
    throw new HardFail("Lob API rate limit exceeded")

  .catch isCausedBy(LobErrors.LobUnauthorizedError), (error) ->
    tables.mail.letters()
    .update
      lob_errors: lob_errors.concat error
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id

    throw new HardFail("Lob API access denied - check configuration/keys")

  .catch isCausedBy(LobErrors.LobForbiddenError), (error) ->
    tables.mail.letters()
    .update
      lob_errors: lob_errors.concat error
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id

    throw new HardFail("Lob API access denied - check configuration/keys")

  .catch isCausedBy(LobErrors.LobBadRequestError), (error) ->
    tables.mail.letters()
    .update
      lob_errors: lob_errors.concat error
      status: 'error-invalid'
      retries: letter.retries + 1
    .where
      id: letter.id

    # Do not throw in this case, since the address is probably undeliverable

  .catch isCausedBy(LobErrors.LobServerError), (error) ->
    tables.mail.letters()
    .update
      lob_errors: lob_errors.concat error
      status: 'error-transient'
      retries: letter.retries + 1
    .where
      id: letter.id

    throw new SoftFail("Lob API server error - retry later")

  .then (lobResponse) ->
    logger.debug "#{JSON.stringify lobResponse, null, 2}"
    tables.mail.letters()
    .update
      lob_response: lobResponse
      status: 'sent'
      retries: letter.retries + 1
    .where
      id: letter.id

subtasks =
  findLetters: findLetters
  sendLetter: sendLetter
  updateLetters: updateLetters
  getLetter: getLetter

module.exports = new TaskImplementation(subtasks)
