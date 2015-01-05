config = require '../config/config'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
renderPdfFile = require '../utils/util.renderPdfFile'
fs = require 'fs'

testLob = promisify.lob(new LobFactory(config.LOB.TEST_API_KEY))
liveLob = promisify.lob(new LobFactory(config.LOB.LIVE_API_KEY))

createNewPdfObject = (Lob, userId, templateId, data) -> Promise.try () ->
  Promise.using renderPdfFile.toFile(templateId, data, partialId: userId).disposer((filename) -> fs.unlinkAsync(filename)),
  (filename) ->
    Lob.objects.createAsync
      file: "@#{filename}"
      setting: 100
      template: renderPdfFile.getLobTemplateId(templateId)
  .then (lobResponse) ->
    lobResponse.id

sendJob = (Lob, userId, templateId, data) -> Promise.try () ->
  createNewPdfObject(Lob, userId, templateId, data)
  .then (objectId) ->
    Lob.jobs.createAsync
      to: data.to
      from: data.from
      objects: [objectId]

module.exports =
  getPriceQuote: (userId, templateId, data) -> Promise.try () ->
    sendJob(testLob, userId, templateId, data)
    .then (lobResponse) ->
      lobResponse.price
  sendSnailMail: (userId, templateId, data) -> sendJob(liveLob, userId, templateId, data)
