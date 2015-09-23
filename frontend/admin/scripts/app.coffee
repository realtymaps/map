'use strict'

require '../../../common/extensions/strings.coffee'
require '../../common/scripts/factories/gridController.coffee'

appName = 'rmapsAdminApp'


app = window.angular.module appName, [
  'rmapsCommon'
  'nemLogging'
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
  'ui.grid.pinning'
  'ui.grid.cellNav'
]

module.exports = app
