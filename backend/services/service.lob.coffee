config = require '../config/config'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
logger = require '../config/logger'
_ = require 'lodash'

testLob = new LobFactory(config.LOB.TEST_API_KEY)
testLob.rm_type = 'test'
promisify.lob(testLob)
liveLob = new LobFactory(config.LOB.LIVE_API_KEY)
liveLob.rm_type = 'live'
promisify.lob(liveLob)


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
    sendJob(testLob, userId, data)
    .then (lobResponse) ->
      lobResponse.price
  sendSnailMail: (userId, templateId, data) -> sendJob(liveLob, userId, data)
