'use strict'

_ = require 'lodash'
require 'angular/angular'
require 'angular-animate'
require 'angular-resource'
require 'angular-route'
require 'angular-ui-router'
require 'angular-cookies'
require 'angular-cache'
require 'angular-simple-logger'
require 'angular-state-files'
require 'angular-ui-bootstrap'
require 'angular-sanitize'
require 'jsonformatter'
require 'rmaps-angular-utils'
window.L = require 'leaflet'
require 'leaflet-search/dist/leaflet-search.src.js'
require 'leaflet.markercluster'#has css
require 'leaflet-zoombox/L.Control.ZoomBox.min.js'#has css
require 'ui-leaflet'
require 'leaflet-plugins/layer/tile/Google.js'

require 'angularjs-slider' #rzModule
require 'angular-stripe'
require 'angular-toastr'
require 'angular-touch'
require 'ui-router-extras'

window.rangy = require 'rangy' #rangy is a global in textangular
require 'rangy/lib/rangy-classapplier.js'
# require 'textangular/dist/textAngular-sanitize.js'
require 'textangular'

require 'ng-file-upload'
require 'ng-infinite-scroll'
require 'angular-numeraljs/dist/angular-numeraljs.js'
require 'angular-load'
require 'angular-credit-cards'

require 'ng-img-crop-full-extended/compile/minified/ng-img-crop.js'#has css

window._ = _
require 'restangular' #requires lodash globally, should fix later

require '../../../common/extensions/index.coffee'
require '../../common/scripts/module.coffee'


require 'leaflet/dist/leaflet.css'
require 'leaflet.markercluster/dist/MarkerCluster.Default.css'
require 'leaflet-zoombox/L.Control.ZoomBox.css'
require 'ng-img-crop-full-extended/compile/unminified/ng-img-crop.css'
require 'angularjs-slider/dist/rzslider.css'
require 'angular-busy/dist/angular-busy.css'
require 'textangular/dist/textAngular.css'
require 'angular-toastr/dist/angular-toastr.css'
require './config/config.chat.js'


app = window.angular.module 'rmapsMapApp', [
  'rmapsCommonUtils'
  'angular-data.DSCacheFactory'
  'angular-stripe'
  'angularLoad'
  'credit-cards'
  'ct.ui.router.extras'
  'infinite-scroll'
  'jsonFormatter'
  'nemLogging'
  'ngAnimate'
  'ngCookies'
  'ngImgCrop'
  'ngNumeraljs'
  'ngResource'
  'ngRoute'
  'ngTouch'
  'restangular'
  'rmapsCommon'
  'rzModule'
  'stateFiles'
  'textAngular'
  'toastr'
  'ui-leaflet'
  'ui.bootstrap'
  'ui.router'
  'ngFileUpload'
  'rmaps-utils'
]

require '../../../tmp/map.templates.js' #requries rmapsMapsApp to be initialized

app.controller 'rmapsAppCtrl', (
$log
$scope
$rootScope
$location
rmapsMainOptions
rmapsPrincipalService) ->

  $log = $log.spawn('rmapsAppCtrl')
  $rootScope.subscriptionConfig = rmapsMainOptions.subscription # expose plan ids for use among jade files
  rmapsPrincipalService.getIdentity().then (identity) ->
    return unless identity
    {user, profiles} = identity
    user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ''
    user.name = user.full_name or user.email
    _.extend $rootScope,
      mainOptions: rmapsMainOptions['map']
      user: user
      profiles: profiles
      isActive: (viewLocation) ->
        locationPath = $location.path().substr(1)
        locationView = if locationPath.lastIndexOf('/') > 0 then locationPath.slice(0, locationPath.lastIndexOf('/')) else $location.path().substr(1)

        active = viewLocation == locationView
        if active
          $rootScope.activeView = viewLocation

        active

app.run (rmapsErrorHandler) ->
  rmapsErrorHandler.captureGlobalErrors()

app.factory '$exceptionHandler', (rmapsErrorHandler) ->
  return (error, cause) ->
    rmapsErrorHandler.captureAngularException error

module.exports = app
