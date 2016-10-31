_ = require 'lodash'
app = require '../app.coffee'
common = require '../../../../common/config/commonConfig.coffee'
Point = require('../../../../common/utils/util.geometries.coffee').Point

naming = do -> # for things we can't make up our minds on for naming context
  save: do ->
    alt =
      past: 'Pinned'
      present: 'Pin'
      plural: 'Pins'
      progressive: 'Pinning'
      un: 'Unpin'
    past = 'Saved'
    progressive = 'Saving'
    present = 'Save'
    plural = 'Saves'
    un = 'Unsave'
    pluralAlt = plural + '/' + alt.plural
    {
      alt
      past
      progressive
      present
      plural
      pluralAlt
      un
    }


mainOptions = do () ->
  isDev = (window.location.hostname == 'localhost' || window.location.hostname == '127.0.0.1')
  res = _.merge common,
    map: {
      naming
      clickDelayMilliSeconds: 300
      redrawDebounceMilliSeconds: 1000
      options:
        logLevel: if isDev then 'debug' else 'error'
        disableDoubleClickZoom: false #does not work well with dblclick properties
        streetViewControl: false
        zoomControl: true
        panControl: false
        maxZoom: 21
        minZoom: 3
        throttle:
          eventPeriods:
            mousewheel: 50 # ms - don't let pass more than one event every 50ms.
            mousemove: 200 # ms - don't let pass more than one event every 200ms.
            mouseout: 200
          space: 2
        json:
          center: _.extend new Point(lat: 26.148111, lon: -81.790809), zoom: 15, where: 'rmapsMainOptions'
    }

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

app.constant 'rmapsMainOptions', mainOptions

module.exports = mainOptions
