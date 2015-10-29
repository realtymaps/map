config = require '../config/config'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
renderPdfFile = require '../utils/util.renderPdfFile'
fs = require 'fs'
logger = require '../config/logger'


testLob = new LobFactory(config.LOB.TEST_API_KEY)

#testLob.setVersion(config.LOB.API_VERSION)
testLob.rm_type = 'test'
promisify.lob(testLob) # can't promisify before setting the version, apparently
liveLob = new LobFactory(config.LOB.LIVE_API_KEY)
#liveLob.setVersion(config.LOB.API_VERSION)
liveLob.rm_type = 'live'
promisify.lob(liveLob) # can't promisify before setting the version, apparently


fileDisposer = (filename) ->
  fs.unlinkAsync(filename)
  .then () ->
    logger.debug "deleted pdf file: #{filename}"

createNewLobObject = (Lob, userId, data) -> Promise.try () ->
  # lobInit = 
  #   description: 'Realty Maps Mailing'
  #   file: data.content
  #   data: data.macros
  #   to: data.recipient
  #   from: data.sender
  #   color: false
  # logger.debug "#### creating letter from data:"
  # logger.debug JSON.stringify(lobInit)
  # logger.debug "#### lob letters:"
  # logger.debug JSON.stringify(Lob.letters)
  # logger.debug "#### Lob keys:"
  # logger.debug Object.keys(Lob)
  # logger.debug "#### Lob.jobs keys:"
  # logger.debug Object.keys(Lob.jobs)
  # logger.debug "#### Lob.objects keys:"
  # logger.debug Object.keys(Lob.objects)
  # logger.debug "#### Lob.addresses keys:"
  # logger.debug Object.keys(Lob.addresses)
  # logger.debug "#### Lob.letters keys:"
  # logger.debug "N/A"

  # Lob.objects.createAsync(lobInit)
  # Lob.letters.createAsync(lobInit)
  Lob.addresses.createAsync(data.recipient)
  .then (lobResponse) ->
    logger.debug "created #{Lob.rm_type} LOB object: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse.id

sendJob = (Lob, userId, data) -> Promise.try () ->
  createNewLobObject(Lob, userId, data)
  .then (address) ->
    logger.debug "got address response:"
    logger.debug address
    logger.debug "from:"
    logger.debug data.sender
    Lob.letters.createAsync
      description: data.description
      #to: address.id
      to: data.recipient
      from: data.sender
      file: data.content
      #data: data.macros
      data: {'name': 'Justin'}
      color: false
  .then (lobResponse) ->
    logger.debug "created #{Lob.rm_type} LOB job: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse

module.exports =
  getPriceQuote: (userId, data) -> Promise.try () ->
    sendJob(testLob, userId, data)
    .then (lobResponse) ->
      logger.debug "\n#### got price!"
      logger.debug lobResponse.price
      lobResponse.price
  sendSnailMail: (userId, templateId, data) -> sendJob(liveLob, userId, data)
