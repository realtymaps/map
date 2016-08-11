request = require 'request'
cartodbConfig = require '../config/cartodb/cartodb'
Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'
request = Promise.promisify(request)
logger = require('../config/logger').spawn('backend:task:cartodb')
errorHandlingUtils = require '../utils/errors/util.error.partiallyHandledError'
{SoftFail} = require '../utils/errors/util.error.jobQueue'
analyzeValue = require '../../common/utils/util.analyzeValue'

###eslint-disable###
wake = (subtask) -> Promise.try ->
  ###eslint-enable###
  cartodbConfig()
  .then (config) ->
    logger.debug '@@@@ cartodb config @@@@'
    logger.debug config

    Promise.all Promise.map config.WAKE_URLS, (url) ->
      logger.debug("Posting Wake URL: #{url}")
      request {
        url: 'http:' + url
        headers:
          'Content-Type': 'application/json;charset=utf-8'
      }
      
    .then () ->
      logger.debug('All Wake Success!!')
    .catch errorHandlingUtils.isUnhandled, (error) ->
      throw new errorHandlingUtils.PartiallyHandledError(error, 'failed wake cartodb')
    .catch (error) ->
      throw new SoftFail(analyzeValue.getSimpleMessage(error))


module.exports = new TaskImplementation('cartodb', {wake})
