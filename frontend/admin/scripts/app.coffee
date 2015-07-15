'use strict'

require '../../../common/extensions/strings.coffee'

# require '../../../bower_components/angular-ui-grid/ui-grid.js'
# require '../../../bower_components/angular-ui-grid/ui-grid.woff'
# require '../../../bower_components/angular-ui-grid/ui-grid.ttf'
# require '../../../bower_components/angular-ui-grid/ui-grid.svg'
# require '../../../bower_components/angular-ui-grid/ui-grid.css'

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
  'infinite-scroll'
  'restangular'
  'cgBusy'
  'ui.grid'
]

module.exports = app
