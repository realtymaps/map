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

filterLobResponseErrors = (res) ->
  if 'errors' not of res
    return
  errorList = _.cloneDeep res.errors
  anError = errorList.pop()
  msg = "#{anError.message}"
  while anError = errorList.pop()
    msg = "#{msg}, #{anError.message}"
  msg = "#{msg}, Placeholder Msg"
  throw new Error(msg) # throw it up for Express to handle

createNewLobObject = (Lob, userId, data) -> Promise.try () ->
  Lob.addresses.createAsync(data.recipient)
  .then (lobResponse) ->
    filterLobResponseErrors(lobResponse)
    lobResponse
  .then (lobResponse) ->
    logger.debug "created #{Lob.rm_type} Lob.addresses: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse.id

sendJob = (Lob, userId, data) -> Promise.try () ->
  createNewLobObject(Lob, userId, data)
  .then (address) ->
    Lob.letters.createAsync
      description: data.description
      #to: address.id
      to: data.recipient
      from: data.sender
      file: data.content
      #file: rawLetterContent2
      #data: data.macros
      data: {'name': 'Justin'}
      color: true
      template: true
  .then (lobResponse) ->
    filterLobResponseErrors(lobResponse)
    lobResponse
  .then (lobResponse) ->
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
