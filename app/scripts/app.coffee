'use strict'

require '../../common/extensions/strings.coffee'

appName = 'app'.ourNs()
#console.info "AppName: #{appName}"

app = window.angular.module appName, [
  'angular-data.DSCacheFactory'
  'uiGmapgoogle-maps'
  'rmaps-utils'
  'ngCookies'
  'ngResource'
  'ngRoute'
  'ui.bootstrap'
  'stateFiles'
  'ui.router'
  'ct.ui.router.extras'
  'ngAnimate'
  'infinite-scroll'
]

module.exports = app
