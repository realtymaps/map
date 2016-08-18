Promise = require 'bluebird'
request = require 'request'
request = Promise.promisify(request)
config = require './config/config'
cartodbConfig = require './config/cartodb/cartodb'
analyzeValue = require '../common/utils/util.analyzeValue'

logger = require('./config/logger').spawn('workers')

wakeCartodb = () -> Promise.try () ->

  myLogger = logger.spawn('wake')
  myLogger.debug 'started'

  cartodbConfig()
  .then (cartoConfig) ->
    myLogger.debug 'Cartodb config:'
    myLogger.debug cartoConfig

    Promise.map cartoConfig.WAKE_URLS, (url) ->
      url = 'http:' + url

      myLogger.debug () -> "Posting Wake URL: #{url}"
      request({url, headers: 'Content-Type': 'application/json;charset=utf-8'})
    .then () ->
      myLogger.debug 'All Wake Success!!'
    .catch (err) ->
      myLogger.error "Unexpected error performing cartoDb wake: #{analyzeValue.getSimpleDetails(err)}"


module.exports = {
  WAKE_CARTODB:
    worker: wakeCartodb
    interval: config.CARTO_WAKE_INTERVAL
}
