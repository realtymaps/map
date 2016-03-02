'use strict'

require '../../../common/extensions/strings.coffee'
require '../../../common/extensions/angular.coffee'

appName = 'rmapsMapApp'

app = window.angular.module appName, [
  'angular-data.DSCacheFactory'
  'angular-stripe'
  'angularLoad'
  'credit-cards'
  'ct.ui.router.extras'
  'google.places'
  'infinite-scroll'
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
  'uiGmapgoogle-maps'
  'validation'
  'validation.rule'
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

require('./controllers/mayday_controllers1.coffee')(app)
