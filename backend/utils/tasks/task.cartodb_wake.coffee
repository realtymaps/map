request = require 'hyperquest'
{CARTODB} =  require '../../config/config'
Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'

module.exports = new TaskImplementation
  wake: (subtask) -> Promise.try ->
    new Promise (resolve,reject) ->
      request.setHeader('Content-Type', 'application/json;charset=utf-8')
      request.on 'error', reject
      request.on 'response', resolve
      CARTODB.WAKE_URLS.forEach (url) ->
        request.post(url)
