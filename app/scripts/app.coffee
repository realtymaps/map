'use strict'

require '../../common/extensions/strings.coffee'

appName = 'app'.ourNs()
console.info "AppName: #{appName}"

#ns() ~ ui-gmap ~ uiGmap
app = window.angular.module appName, [
  'uiGmapgoogle-maps'
  'ngCookies'
  'ngResource'
  'ngRoute'
  'ui.bootstrap'
  'stateFiles'
  'ui.router'
  'ct.ui.router.extras'
  'ngAnimate'
]

module.exports = app
