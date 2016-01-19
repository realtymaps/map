externalAccounts = require '../services/service.externalAccounts'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
logger = require '../config/logger'
_ = require 'lodash'

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

checkLobResponseErrors = (res) ->
  return if not res.errors?.length
  msg = _.pluck res.errors, 'message'
  msg = msg.reverse().join(', ')
  throw new Error("LOB returned error(s): #{msg}")

sendJob = (Lob, userId, data) -> Promise.try () ->
  Lob.addresses.createAsync(data.recipient)
  .then (lobResponse) ->
    checkLobResponseErrors(lobResponse)
    logger.debug "created #{Lob.rm_type} Lob.addresses: #{JSON.stringify(lobResponse, null, 2)}"

    Lob.letters.createAsync
      description: data.description
      to: data.recipient
      from: data.sender
      file: data.content
      data: {'name': 'Justin'}
      color: true
      template: true

  .then (lobResponse) ->
    checkLobResponseErrors(lobResponse)
    logger.debug "created #{Lob.rm_type} Lob.letters: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse

module.exports =
  getPriceQuote: (userId, data) -> Promise.try () ->
    lobPromise
    .then (lob) ->
      sendJob(lob.test, userId, data)
      .then (lobResponse) ->
        lobResponse.price

  sendSnailMail: (userId, data) ->
    lobPromise
    .then (lob) ->
      sendJob(lob.live, userId, data)
