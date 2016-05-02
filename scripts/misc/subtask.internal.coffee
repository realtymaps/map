cluster = require '../../backend/config/cluster'
_ =  require 'lodash'
Promise = require 'bluebird'


getNextSubtask = (task, taskName) ->
  console.log "fake get next subtask #{taskName}"
  task.subtasks[taskName]

runPagedSubtask = ({task, subtask, totalOrList, maxPage, laterSubtaskName, mergeData}) ->
  subtask.data = _.merge {}, subtask.data, mergeData,
    values: totalOrList

  console.log "Fake Pagenate taskName: #{laterSubtaskName}"
  console.log "Fake Pagenate totalOrList: #{totalOrList}"
  console.log "Fake Pagenate maxPage: #{maxPage}"
  if !totalOrList
    throw new Error "totalOrList undefined"

  return getNextSubtask(task, laterSubtaskName)(subtask)



subtaskFork = ({task, chunkIndex, totalChunks, pagedPerProcess, subtask, maxPage, laterSubtaskName, mergeData}) ->
  console.log "chunkIndex: #{chunkIndex}"
  # {workerCount: 2} having issues forking process due to shell script and coffee forkin
  # tried renaming subtask.coffee and it still does not work correctly
  # leaving subtask as shell script and not forking process
  cluster 'subtask', {}, () ->
    workers = []
    for i in [1..pagedPerProcess]
      totalChunk = totalChunks[((chunkIndex+1)*i)-1]
      if !totalChunk
        break
      workers.push runPagedSubtask {
        task
        subtask
        totalOrList: totalChunk
        maxPage
        laterSubtaskName
        mergeData
      }
    Promise.all(workers)

module.exports = {
  runPagedSubtask
  subtaskFork
  getNextSubtask
}
