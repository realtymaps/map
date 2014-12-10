config = require './config'

#match ui-gmap log levels
LOG_LEVELS =
  log: 1
  info: 2
  debug: 3
  warn: 4
  error: 5
  none: 6

module.exports =
  map:
    zoomThresholdMilliSeconds: 1500
    options:
      doLog: true
      logLevel: LOG_LEVELS.debug
      streetViewControl: false
      zoomControl: true
      panControl: false
      maxZoom: 20
      minZoom: 3
      parcelsZoomThresh: 17
      clusteringThresh: 14
      json:
        zoom: 15
        center:
          latitude: 26.148111
          longitude: -81.790809

  doLog: config.LOGGING.FRONT_END
