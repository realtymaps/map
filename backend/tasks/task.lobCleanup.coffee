Promise = require "bluebird"
jobQueue = require '../utils/util.jobQueue'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
tables = require '../config/tables'
_ = require 'lodash'
TaskImplementation = require './util.taskImplementation'
lobSvc = require '../services/service.lob'
LobErrors = require '../utils/errors/util.errors.lob'
{isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
logger = require('../config/logger').spawn('task:lob')
config = require '../config/config'

#
# This task identifies letters that were sent to LOB but we have no response/status data saved
#   Such a scenario could arise due to a network timeout
#
updateLetters = (subtask) ->
  query = tables.mail.letters()
  query
  .select(
    query.raw("id, lob_response, options->'metadata'->'uuid' as uuid, to_char(rm_inserted_time, 'YYYY-MM-DD') as created_date, lob_api")
  )
  .whereNull('lob_response')
  .where(status: 'error-transient')
  .where('retries', '<=', config.MAILING_PLATFORM.LOB_MAX_RETRIES)
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

  lob_errors = []
  if letter.lob_errors?
    lob_errors = lob_errors.concat letter.lob_errors

  if not letter?.uuid
    logger.debug "Letter #{letter.id} has no uuid!"
    return tables.mail.letters()
    .update
      status: 'error-invalid'
    .where
      id: letter.id

  lobSvc.listLetters
    limit: 2 # More than one result is unexpected and we want to know about it
    date_created:
      gte: created_date
    metadata:
      uuid: letter.uuid # unique identifier we generated
   ,
    letter.lob_api

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
        lob_response: data
        status: 'sent'
      .where
        id: letter.id

      throw new SoftFail("Mutltiple copies of letter ID #{letter.id} returned by LOB!")

subtasks =
  updateLetters: updateLetters
  getLetter: getLetter

module.exports = new TaskImplementation(subtasks)