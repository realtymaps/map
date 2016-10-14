###globals _###
'use strict'

require 'angular-ui-bootstrap'
require '../../../common/extensions/index.coffee'

appName = 'rmapsMapApp'

app = window.angular.module appName, [
  'rmapsCommonUtils'

  'angular-data.DSCacheFactory'
  'angular-stripe'
  'angularLoad'
  'credit-cards'
  'ct.ui.router.extras'
  'google.places'
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
  'rmaps-utils'
  'rmapsCommon'
  'rzModule'
  'stateFiles'
  'textAngular'
  'toastr'
  'ui-leaflet'
  'ui.bootstrap'
  'ui.router'
  'validation'
  'validation.rule'
  'ngFileUpload'
]

app.controller 'rmapsAppCtrl', ($scope, $rootScope, $location, rmapsPrincipalService) ->

  rmapsPrincipalService.getIdentity().then (identity) ->
    return unless identity
    {user, profiles} = identity
    user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ''
    user.name = user.full_name or user.username

    _.extend $rootScope,
      user: user
      profiles: profiles
      isActive: (viewLocation) ->
        locationPath = $location.path().substr(1)
        locationView = if locationPath.lastIndexOf('/') > 0 then locationPath.slice(0, locationPath.lastIndexOf('/')) else $location.path().substr(1)

        active = viewLocation == locationView
        if active
          $rootScope.activeView = viewLocation

        active


module.exports = app
