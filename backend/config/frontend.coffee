config = require './config'
module.exports =
  map:
    zoomThresholdMilliSeconds: 1250
    options:
      doLog: false
      streetViewControl: false
      zoomControl: false
      panControl: false
      maxZoom: 20
      minZoom: 3
      parcelsZoomThresh: 16
      clusteringThresh: 14
      json:
        zoom: 15
        center:
          latitude: 26.148111
          longitude: -81.790809


  doLog: config.LOGGING.FRONT_END
