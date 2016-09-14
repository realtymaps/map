Promise = require 'bluebird'
request = require 'request'
request = Promise.promisify(request)
config = require '../config/config'
cartodbConfig = require '../config/cartodb/cartodb'
analyzeValue = require '../../common/utils/util.analyzeValue'

logger = require('../config/logger').spawn('workers:wake_cartodb')

wakeCartodb = () -> Promise.try () ->

  logger.debug 'started'

  cartodbConfig()
  .then (cartoConfig) ->
    logger.debug 'Cartodb config:'
    logger.debug cartoConfig

    Promise.map cartoConfig.WAKE_URLS, (url) ->
      url = 'http:' + url

      logger.debug () -> "Posting Wake URL: #{url}"
      request({url, headers: 'Content-Type': 'application/json;charset=utf-8'})
    .then () ->
      logger.debug 'All Wake Success!!'
    .catch (err) ->
      logger.error "Unexpected error performing cartoDb wake: #{analyzeValue.getSimpleDetails(err)}"


module.exports = {
  worker: wakeCartodb
  interval: config.CARTO_WAKE_INTERVAL
  silentWait: 0
  gracefulTermination: 1
  kill: 2
  crash: 3
}
