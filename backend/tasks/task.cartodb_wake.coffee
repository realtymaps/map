request = require 'hyperquest'
cartodbConfig = require '../config/cartodb/cartodb'
Promise = require 'bluebird'
TaskImplementation = require './util.taskImplementation'


wake = (subtask) -> Promise.try ->
  cartodbConfig()
  .then (config) ->
    new Promise (resolve,reject) ->
      request.setHeader('Content-Type', 'application/json;charset=utf-8')
      request.on 'error', reject
      request.on 'response', resolve
      config.WAKE_URLS.forEach (url) ->
        request.post(url)


module.exports = new TaskImplementation {
  wake
}
