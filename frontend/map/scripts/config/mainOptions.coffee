###globals _###
app = require '../app.coffee'
common = require '../../../../common/config/commonConfig.coffee'
Point = require('../../../../common/utils/util.geometries.coffee').Point

app.constant 'rmapsMainOptions', do () ->
  isDev = (window.location.hostname == 'localhost' || window.location.hostname == '127.0.0.1')
  res = _.merge common,
    map:
      clickDelayMilliSeconds: 300
      redrawDebounceMilliSeconds: 700
      options:
        logLevel: if isDev then 'debug' else 'error'
        disableDoubleClickZoom: false #does not work well with dblclick properties
        uiGmapLogLevel: 'error'
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
          center: _.extend Point(lat: 26.148111, lon: -81.790809), zoom: 15

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

    mail:
      macros:
        address: '{{address}}'
        name: '{{name}}'
      s3_upload:
        host: 'https://rmaps-pdf-uploads.s3.amazonaws.com'
        AWSAccessKeyId: 'AKIAI2DY7QCTZ2U3DJJQ'
        #base64 encoded policy: to enforce upload restriction to pdf only
        #https://aws.amazon.com/articles/1434
        #decode w https://www.npmjs.com/package/js-base64
        policy: 'eyJleHBpcmF0aW9uIjogIjIwMzYtMDEtMDFUMDA6MDA6MDBaIiwKICAiY29uZGl0aW9ucyI6IFsgCiAgICB7ImJ1Y2tldCI6ICJybWFwcy1wZG' +
          'YtdXBsb2FkcyJ9LCAKICAgIFsic3RhcnRzLXdpdGgiLCAiJGtleSIsICJ1cGxvYWRzLyJdLAogICAgeyJhY2wiOiAicHJpdmF0ZSJ9LAogICAgWyJzdG' +
          'FydHMtd2l0aCIsICIkQ29udGVudC1UeXBlIiwgImFwcGxpY2F0aW9uL3BkZiJdLAogICAgWyJjb250ZW50LWxlbmd0aC1yYW5nZSIsIDAsIDEwNzM3NDE4MjRdCiAgXQp9'
        signature: 'wvcT2Cp1Qb6a2XI59tr/vwjN1Vs='
      statusNames:
        ready: 'draft'
        sending: 'pending'
        paid: 'sent'
      sizeErrorMsg: 'Please select/upload a file that has correct dimensions for its type: 8.5" x 11" for Letters.'
  res
