app = require '../app.coffee'

app.constant 'MainOptions'.ourNs(), do () ->
  #match ui-gmap log levels
  LOG_LEVELS =
    log: 1
    info: 2
    debug: 3
    warn: 4
    error: 5
    none: 6

  return {
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
    # do logging for local dev only
    doLog: (window.location.hostname == 'localhost' || window.location.hostname == '127.0.0.1')
    # logoutDelayMillis is how long to pause on the logout view before redirecting
    logoutDelayMillis: 1500
    # filterDrawDelay is how long to wait when filters are modified to see if more modifications are incoming before querying
    filterDrawDelay: 1000
  }
