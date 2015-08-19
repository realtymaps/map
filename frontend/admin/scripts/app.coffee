'use strict'

require '../../../common/extensions/strings.coffee'

appName = 'rmapsAdminApp'


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
  'ui.grid.resizeColumns'
  'ui.grid.edit'
  'ui.grid.autoResize'
]

module.exports = app

require './require.coffee'
