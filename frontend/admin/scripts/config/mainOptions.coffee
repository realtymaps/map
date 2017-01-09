app = require '../app.coffee'
common = require '../../../../common/config/commonConfig.coffee'
_ = require 'lodash'


app.constant 'rmapsMainOptions', do () ->
  isDev = (window.location.hostname == 'localhost' || window.location.hostname == '127.0.0.1' || window.location.hostname == 'dev.realtymaps.com')
  res = _.merge common,
    # logoutDelayMillis is how long to pause on the logout view before redirecting
    logoutDelayMillis: 1500
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
