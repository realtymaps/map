config = require '../config/config'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
renderPdfFile = require '../utils/util.renderPdfFile'
fs = require 'fs'
logger = require '../config/logger'

testLob = promisify.lob(new LobFactory(config.LOB.TEST_API_KEY))
testLob.rm_type = 'test'
liveLob = promisify.lob(new LobFactory(config.LOB.LIVE_API_KEY))
liveLob.rm_type = 'live'

fileDisposer = (filename) ->
  fs.unlinkAsync(filename)
  .then () ->
    logger.debug "deleted pdf file: #{filename}"

createNewPdfObject = (Lob, userId, templateId, data) -> Promise.try () ->
  Promise.using renderPdfFile.toFile(templateId, data, partialId: userId).disposer(fileDisposer),
  (filename) ->
    logger.debug "created pdf file: #{filename}"
    Lob.objects.createAsync
      file: "@#{filename}"
      setting: 100
      template: renderPdfFile.getLobTemplateId(templateId)
  .then (lobResponse) ->
    logger.debug "created #{Lob.rm_type} LOB object: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse.id

sendJob = (Lob, userId, templateId, data) -> Promise.try () ->
  createNewPdfObject(Lob, userId, templateId, data)
  .then (objectId) ->
    Lob.jobs.createAsync
      to: data.to
      from: data.from
      object1: objectId
  .then (lobResponse) ->
    logger.debug "created #{Lob.rm_type} LOB job: #{JSON.stringify(lobResponse, null, 2)}"
    lobResponse

module.exports =
  getPriceQuote: (userId, templateId, data) -> Promise.try () ->
    sendJob(testLob, userId, templateId, data)
    .then (lobResponse) ->
      lobResponse.price
  sendSnailMail: (userId, templateId, data) -> sendJob(liveLob, userId, templateId, data)
