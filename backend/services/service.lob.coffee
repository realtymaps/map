externalAccounts = require '../services/service.externalAccounts'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
logger = require '../config/logger'
_ = require 'lodash'
config = require '../config/config'
{PartiallyHandledError, isUnhandled} = require '../utils/errors/util.error.partiallyHandledError'

lobPromise = Promise.try () ->
  externalAccounts.getAccountInfo('lob')
  .then (accountInfo) ->
    test = new LobFactory(accountInfo.other.test_api_key)
    test.rm_type = 'test'
    promisify.lob(test)
    live = new LobFactory(accountInfo.api_key)
    live.rm_type = 'live'
    promisify.lob(live)
    { test, live }

createLetters = (Lob, userId, data) -> Promise.try () ->
  if !_.isArray(data.recipients)
    throw new PartiallyHandledError("recipients must be an array")

  Promise.map data.recipients, (recipient) ->
    logger.debug "LOB-#{Lob.rm_type} new letter to: #{JSON.stringify(recipient, null, 2)}"

    Lob.letters.createAsync
      description: data.description
      to: recipient
      from: data.sender
      file: data.content
      data: { userId }
      color: true
      template: true

    .catch isUnhandled, (err) ->
      lobError = new Error(err.message)
      throw new PartiallyHandledError(err, "LOB[#{Lob.rm_type}] API responded #{err.status_code}")

    .then (lobResponse) ->
      lobResponse

module.exports =
  getPriceQuote: (userId, data) ->
    lobPromise
    .then (lob) ->
      createLetters lob.test, userId, data
    .then (lobResponses) ->
      _.reduce (_.pluck lobResponses, 'price'), (total, price) ->
        total + Number(price)

  sendSnailMail: (userId, data) ->
    lobPromise
    .then (lob) ->
      throw new Error("Refusing to send snail mail from non-production environment") unless config.ENV == 'production'
      createLetters lob.live, userId, data
    .then (lobResponses) ->
      lobResponses
