Promise = require "bluebird"
jobQueue = require '../services/service.jobQueue'
{SoftFail, HardFail} = require '../utils/errors/util.error.jobQueue'
tables = require '../config/tables'
_ = require 'lodash'
TaskImplementation = require './util.taskImplementation'
LobErrors = require '../utils/errors/util.errors.lob'
lobSvc = require '../services/service.lob'
{PartiallyHandledError, isUnhandled, isCausedBy} = require '../utils/errors/util.error.partiallyHandledError'
logger = require('../config/logger').spawn('task:lobCleanup')
config = require '../config/config'

#
# This task identifies letters that were sent to LOB but we have no response/status data saved
#   Such a scenario could arise due to a network timeout
#
updateLetters = (subtask) ->
  query = tables.mail.letters()
  query
  .select(
    query.raw("id, options->'metadata'->'uuid' as uuid, to_char(rm_inserted_time, 'YYYY-MM-DD') as created_date, retries, lob_api")
  )
  .where(status: 'error-transient')
  .then (letters) ->
    Promise.map letters, (letter) ->
      jobQueue.queueSubsequentSubtask({subtask, laterSubtaskName: 'getLetter', manualData: letter, replace: true})

#
# This task queries the LOB API for letters with an unknown status.
#   If LOB has no record of the letter, we mark the status ready so it will be resent.
#   If LOB has saved the letter, we mark the status sent and save the response data.
#   https://lob.com/docs#letters_list
#
getLetter = (subtask) ->
  letter = subtask.data

  Promise.try ->
    if not letter?.uuid
      logger.debug "Letter #{letter.id} has no uuid! Marking invalid"
      return tables.mail.letters()
      .update
        status: 'error-invalid'
      .where
        id: letter.id

    if letter.retries >= config.MAILING_PLATFORM.LOB_MAX_RETRIES
      return tables.mail.letters()
      .update
        status: 'error-max-retries'
      .where id: letter.id

    lobSvc.listLetters
      date_created:
        gte: letter.created_date
      metadata:
        uuid: letter.uuid # unique identifier we generated
     ,
      letter.lob_api

    .then ({data}) ->
      # In this case we know the letter was recieved by LOB so we can mark it sent
      if data.length == 1
        logger.debug "Marking letter #{letter.uuid} 'sent', since LOB has a match"
        tables.mail.letters()
        .update
          lob_response: data[0]
          status: 'sent'
        .where
          id: letter.id

      # In this case we can assume LOB never created the letter, so we want to retry
      else if data.length == 0
        logger.debug "Marking letter #{letter.uuid} 'ready', since LOB has no match"
        tables.mail.letters()
        .update
          status: 'ready'
        .where
          id: letter.id

      # Wtf, there should not be two letters with the same uuid
      else
        logger.debug "Marking letter #{letter.uuid} 'sent', since LOB has matches"
        tables.mail.letters()
        .update
          lob_response: data
          status: 'sent'
        .where
          id: letter.id
        .then ->
          throw new SoftFail("Mutltiple letters with uuid #{letter.uuid} found. This is unexpected!")

    .catch  LobErrors.LobRateLimitError,
            LobErrors.LobUnauthorizedError,
            LobErrors.LobForbiddenError,
            (error) ->
              throw new HardFail(error)

    .catch  LobErrors.LobBadRequestError,
            LobErrors.LobServerError,
            (error) ->
              throw new SoftFail(error)

    .catch isUnhandled, (error) ->
      throw new SoftFail(error)

subtasks =
  updateLetters: updateLetters
  getLetter: getLetter

module.exports = new TaskImplementation(subtasks)
