externalAccounts = require '../services/service.externalAccounts'
promisify = require '../config/promisify'
Promise = require 'bluebird'
LobFactory = require 'lob'
renderPdfFile = require '../utils/util.renderPdfFile'
fs = require 'fs'
logger = require '../config/logger'


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
    lobPromise
    .then (lob) ->
      sendJob(lob.test, userId, templateId, data)
    .then (lobResponse) ->
      lobResponse.price
  sendSnailMail: (userId, templateId, data) ->
    lobPromise
    .then (lob) ->
      sendJob(lob.live, userId, templateId, data)
