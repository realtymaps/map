_ = require 'lodash'
logger = require('../../config/logger').spawn('task:helpers')

SubtaskHandler =
  compose: (extensions...) ->
    obj = {}
    _.extend obj, SubtaskHandler

    for toExtend in extensions
      _.extend obj, toExtend
    obj
  thirdPartyService: (subtask) ->
  removalService: (subtask) ->
  updateService: (subtask) ->
  invalidRequestErrorType: null
  invalidRequestRegex: null
  errorHandler: (error, handleObj) ->
  handle: (subtask) ->
    removeFromErrorQueue = () =>
      @removalService subtask

    @thirdPartyService subtask
    .then removeFromErrorQueue
    .catch (error) =>
      logger.debug subtask.data, true

      subtask.data.errors.push error

      handleObj = {}
      handleObj["default"] = () =>
        logger.debug "subtask default handle updating error queue"
        logger.debug error, true
        @updateService(subtask)

      handleObj[@invalidRequestErrorType] = () =>
        if @invalidRequestRegex.test error.message
          logger.debug "invalidRequestRegex match on #{error.message}"
          removeFromErrorQueue()

      @errorHandler error, handleObj

module.exports =
  SubtaskHandler: SubtaskHandler
