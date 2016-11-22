'use strict'

window._ = require 'lodash'
require 'angular/angular'
require 'angular-animate'
require 'angular-resource'
require 'angular-route'
require 'angular-ui-router'
require 'angular-busy'
require 'angular-cookies'
require 'angular-cache'
require 'angular-simple-logger'
require 'angular-state-files'
require 'angular-ui-grid/ui-grid.js'
require 'angular-ui-router'
require 'angular-ui-bootstrap'
require 'rmaps-angular-utils'
require 'ng-infinite-scroll'
require 'ui-router-extras/release/ct-ui-router-extras.js'
require 'restangular'#requires lodash globally


require '../../../common/extensions/strings.coffee'
require '../../../common/extensions/angular.coffee'
require '../../../common/utils/angularModule.coffee'
require '../../common/scripts/factories/gridController.coffee'

require 'angular-busy/angular-busy.css'
require 'angular-ui-grid/ui-grid.css'

appName = 'rmapsAdminApp'


app = window.angular.module appName, [
  'rmapsCommon'
  'rmapsCommonUtils'
  'nemLogging'
  'angular-data.DSCacheFactory'
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
  'ui.grid.selection'
]

require '../../../tmp/admin.templates.js' #requries rmapsAdminApp to be initialized

module.exports = app

require './runners/template-cache-hack.coffee'
