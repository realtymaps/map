app = require '../app.coffee'

app.constant 'MainOptions'.ourNs(), do () ->
  isDev = (window.location.hostname == 'localhost' || window.location.hostname == '127.0.0.1')
  return {
    map:
      zoomThresholdMilliSeconds: 1500
      options:
        logLevel: if isDev then 'debug' else 'error'
        streetViewControl: false
        zoomControl: true
        panControl: false
        maxZoom: 20
        minZoom: 3
        parcelsZoomThresh: 17
        clusteringThresh: 17
        json:
          zoom: 15
          center:
            latitude: 26.148111
            longitude: -81.790809
    # do logging for local dev only
    doLog: if isDev then true else false
    # logoutDelayMillis is how long to pause on the logout view before redirecting
    logoutDelayMillis: 1500
    # filterDrawDelay is how long to wait when filters are modified to see if more modifications are incoming before querying
    filterDrawDelay: 1000
    isDev: isDev
  }
