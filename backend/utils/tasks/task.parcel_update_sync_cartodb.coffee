{parcel} = require '../../services/service.cartodb'
Promise =  require 'bluebird'


module.exports =
  executeSubtask: (subtask) -> Promise.try ->
    fipsCode = subtask.data
    parcel.upload(fipsCode)
    .then ->
        parcel.synchronize(fipsCode)
