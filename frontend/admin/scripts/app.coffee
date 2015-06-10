'use strict'

require '../../../common/extensions/strings.coffee'

appName = 'rmapsadminapp'

app = window.angular.module appName, [
  'logglyLogger.logger'
  'angular-data.DSCacheFactory'
  'leaflet-directive'
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
  'infinite-scroll',
  'restangular',
  'ngDragDrop'
]

module.exports = app
