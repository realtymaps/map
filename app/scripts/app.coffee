'use strict'

require '../styles/common.styl'
require '../../common/extensions/strings.coffee'

#console.log "ANGULAR: #{_.keys(angular)}"

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
  'ngAnimate'
]

module.exports = app
