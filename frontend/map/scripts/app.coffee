'use strict'

require '../../../common/extensions/strings.coffee'
require '../../../common/extensions/angular.coffee'

appName = 'rmapsMapApp'

app = window.angular.module appName, [
  'rmapsCommon'
  'nemLogging'
  'angular-data.DSCacheFactory'
  'ui-leaflet'
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
  'validation'
  'validation.rule'
  'ngImgCrop'
  'toastr'
  'textAngular'
]

app.controller 'rmapsAppController', ($scope, $rootScope, $location, rmapsprincipal) ->

  rmapsprincipal.getIdentity().then (identity) ->
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
require('./controllers/mayday_controllers2.coffee')(app)
