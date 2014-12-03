config = require './config'
module.exports =
  map:
    zoomThresholdMilliSeconds: 1500
    options:
      doLog: true
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
