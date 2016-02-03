logger = require('../../config/logger').spawn('task:helpers')
{notImplemented} = require '../util.interface.helpers'
Composable = require '../util.composable'

SubtaskHandlerInterface = Composable.compose
  handler: (subtask) ->
    notImplemented()

SubtaskHandlerThirdpartyInterface = SubtaskHandlerInterface.compose
  thirdPartyService: (subtask) -> notImplemented()
  removalService: (subtask) -> notImplemented()
  updateService: (subtask) -> notImplemented()
  errorHandler: (error, handleObj) -> notImplemented()

  invalidRequestErrorType: null
  invalidRequestRegex: null

SubtaskHandlerThirdparty = SubtaskHandlerThirdpartyInterface.compose
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
  SubtaskHandlerInterface: SubtaskHandlerInterface
  SubtaskHandlerThirdpartyInterface: SubtaskHandlerThirdpartyInterface
  SubtaskHandlerThirdparty: SubtaskHandlerThirdparty
