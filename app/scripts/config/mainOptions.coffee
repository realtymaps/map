app = require '../app.coffee'
common = require '../../../common/config/commonConfig.coffee'

app.constant 'MainOptions'.ourNs(), do () ->
  isDev = (window.location.hostname == 'localhost' || window.location.hostname == '127.0.0.1')
  res = _.merge common,
    map:
      clickDelayMilliSeconds: 300
      zoomThresholdMilliSeconds: 800
      options:
        logLevel: if isDev then 'debug' else 'error'
        disableDoubleClickZoom: false #does not work well with dblclick properties
        uiGmapLogLevel: 'error'
        streetViewControl: false
        zoomControl: true
        panControl: false
        maxZoom: 20
        minZoom: 3
        throttle:
          eventPeriods:
            mousewheel: 50 # ms - don't let pass more than one event every 50ms.
            mousemove: 200 # ms - don't let pass more than one event every 200ms.
            mouseout: 200
          space: 2
        json:
          zoom: 15
          center:
            latitude: 26.148111
            longitude: -81.790809
        styles: [
          {
            featureType: "poi.business",
            elementType: "labels.text",
            stylers: [
              { visibility: "off" }
            ]
          },
          {
            featureType: "poi.business",
            elementType: "labels.icon",
            stylers: [
              { "visibility": "off" }
            ]
          },
          {
            featureType: "poi.place_of_worship",
            elementType: "labels.text",
            stylers: [
              { visibility: "off" }
            ]
          },
          {
            featureType: "poi.place_of_worship",
            elementType: "labels.icon",
            stylers: [
              { visibility: "off" }
            ]
          },
          {
            "featureType": "landscape",
            "stylers": [
              {
                "hue": "#F1FF00"
              },
              {
                "saturation": -27.4
              },
              {
                "lightness": 9.4
              },
              {
                "gamma": 1
              }
            ]
          },
          {
            "featureType": "road.highway",
            "stylers": [
              {
                "hue": "#0099FF"
              },
              {
                "saturation": -20
              },
              {
                "lightness": 36.4
              },
              {
                "gamma": 1
              }
            ]
          },
          {
            "featureType": "road.arterial",
            "stylers": [
              {
                "hue": "#00FF4F"
              },
              {
                "saturation": 0
              },
              {
                "lightness": 0
              },
              {
                "gamma": 1
              }
            ]
          },
          {
            "featureType": "road.local",
            "stylers": [
              {
                "hue": "#FFB300"
              },
              {
                "saturation": -38
              },
              {
                "lightness": 11.2
              },
              {
                "gamma": 1
              }
            ]
          },
          {
            "featureType": "water",
            "stylers": [
              {
                "hue": "#00B6FF"
              },
              {
                "saturation": 4.2
              },
              {
                "lightness": -63.4
              },
              {
                "gamma": 1
              }
            ]
          },
          {
            "featureType": "poi",
            "stylers": [
              {
                "hue": "#9FFF00"
              },
              {
                "saturation": 0
              },
              {
                "lightness": 0
              },
              {
                "gamma": 1
              }
            ]
          }
        ]
    # do logging for local dev only
    doLog: if isDev then true else false
    # logoutDelayMillis is how long to pause on the logout view before redirecting
    logoutDelayMillis: 1500
    # filterDrawDelay is how long to wait when filters are modified to see if more modifications are incoming before querying
    filterDrawDelay: 1000
    isDev: isDev
    pdfRenderDelay: 250

    alert:
      # ttlMillis is the default for how long to display an alert before automatically hiding it
      ttlMillis: 2 * 60 * 1000   # 2 minutes
      # quietMillis is the default for how long is needed before we start to show a previously-closed alert if it happens again
      quietMillis: 30 * 1000   # 30 seconds
      # cancelQuietMillis is how long to prevent alerts when we expect an HTTP cancel
      cancelQuietMillis: 1000 # 1 second, just in case of a really bogged down browser; on my laptop, only 8ms is necessary
  res