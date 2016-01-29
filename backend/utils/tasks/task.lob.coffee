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

#
# This task identifies letters that were sent to LOB but we have no response/status data saved
#   Such a scenario could arise due to a network timeout
#
updateLetters = (subtask) ->
  tables.mail.letters()
  .select(
    [
      'id'
      "options->'metadata'->'uuid' as uuid"
      'date(rm_inserted_time) as created_date'
    ]
  )
  .whereNull('lob_response')
  .where(status: 'error-transient')
  .then (letters) ->
    Promise.map letters, (letter) ->
      jobQueue.queueSubsequentSubtask null, subtask, 'lob_getLetter', letter, true

#
# This task queries the LOB API for letters with an unknown status.
#   If LOB has no record of the letter, we mark the status ready so it will be resent.
#   If LOB has a saved the letter, we mark the status sent and save the response data.
#   https://lob.com/docs#letters_list
#
getLetter = (subtask) ->
  letter = subtask.data

  if not letter.uuid
    logger.debug "Letter #{letter.id} has no uuid!"
    return tables.mail.letters()
    .update
      status: 'error-no-uuid'
    .where
      id: letter.id

  lobSvc.listLetters
    limit: 2 # More than one result is unexpected and we want to know about it
    date_created:
      gte: created_date
    metadata:
      uuid: letter.options.metadata.uuid # unique identifier we generated

  .then ({data}) ->
    # In this case we know the letter was recieved by LOB so we can mark it sent
    if data.length == 1
      tables.mail.letters()
      .update
        lob_response: data[0]
        status: 'sent'
      .where
        id: letter.id

    # In this case we can assume LOB never created the letter, so we want to retry
    else if data.length == 0
      tables.mail.letters()
      .update
        status: 'ready'
      .where
        id: letter.id

    # Wtf, there should not be two letters with the same uuid
    else
      tables.mail.letters()
      .update
        lob_response: data[0]
        status: 'sent-duplicate'
      .where
        id: letter.id

      throw new SoftFail("Mutltiple copies of letter ID #{letter.id} returned by LOB!")

subtasks =
  findLetters: findLetters
  sendLetter: sendLetter
  updateLetters: updateLetters
  getLetter: getLetter

module.exports = new TaskImplementation(subtasks)
