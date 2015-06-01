{uploadToParcelsDb} = require '../../services/service.parcels.saver'

module.exports =
  executeSubtask: (subtask) ->
    fipsCode = subtask.data
    uploadToParcelsDb(fipsCode)
