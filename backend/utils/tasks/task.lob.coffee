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

findLetters = (subtask) ->
  tables.mail.letters()
  .select(
    [
      'id'
      'address_to as to'
      'address_from as from'
      'file'
      'options'
      'retries'
    ]
  )
  .where(
    status: 'ready'
  )
  .then (letters) ->
    Promise.map letters, (letter) ->
      jobQueue.queueSubsequentSubtask null, subtask, 'lob_createLetter', letter, true

sendLetter = (subtask) ->
  tables.jobQueue.currentSubtasks().where(name:'lob_createLetter').then ([subtask]) ->

    letter = subtask.data

    console.log "#{JSON.stringify letter}"

    lobSvc.createLetterTest letter

    .catch isCausedBy(LobErrors.LobRateLimitError), (error) ->
      tables.mail.letters()
      .update
        lob_response: error
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id
      throw new HardFail("Lob API rate limit exceeded")

    .catch isCausedBy(LobErrors.LobUnauthorizedError), (error) ->
      tables.mail.letters()
      .update
        lob_response: error
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id

      throw new HardFail("Lob API access denied - check configuration/keys")

    .catch isCausedBy(LobErrors.LobForbiddenError), (error) ->
      tables.mail.letters()
      .update
        lob_response: error
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id

      throw new HardFail("Lob API access denied - check configuration/keys")

    .catch isCausedBy(LobErrors.LobBadRequestError), (error) ->
      tables.mail.letters()
      .update
        lob_response: error
        status: 'error-invalid'
        retries: letter.retries + 1
      .where
        id: letter.id

      throw new SoftFail("Lob API bad request/input")

    .catch isCausedBy(LobErrors.LobServerError), (error) ->
      tables.mail.letters()
      .update
        lob_response: error
        status: 'error-transient'
        retries: letter.retries + 1
      .where
        id: letter.id

      throw new SoftFail("Lob API server error - retry later")

    .then (lobResponse) ->
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

module.exports = new TaskImplementation(subtasks)
