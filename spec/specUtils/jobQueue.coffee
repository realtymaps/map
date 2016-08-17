SqlMock = require './sqlMock.coffee'

queueSubsequentSubtask = ({transaction, subtask, laterSubtaskName, manualData, replace, concurrency}) ->
  

  # subtasksToRun = 0
  # promises = []
  # if _.isArray manualData
  #   for data in manualData
  #     console.log "subtasksToRun: #{subtasksToRun}"
  #     newSubtask = _.merge {}, subtask,
  #       data: data
  #     promises.push internal.getNextSubtask(task, laterSubtaskName)(newSubtask)

  #     subtasksToRun++

  #     if subtasksToRun >= parseInt(argv.subtasksToRun)
  #       console.log "SUBTASK SHOULD BREAK!!!!!!!!!"
  #       break
  # Promise.all promises


class JobQueueMock
  constructor: (@taskModule) ->
    console.log "got taskModule..."


  rewireJobQueue: () ->


module.exports = JobQueueMock
