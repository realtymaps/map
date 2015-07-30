'use strict'

require '../../../common/extensions/strings.coffee'
require '../../../common/extensions/angular.coffee'


#Wierd this does not work well render problems.. bower is fine
require '../../../bower_components/leaflet-plugins/layer/tile/Google.js'
require '../../../bower_components/leaflet/dist/leaflet.css'
#leaflet stylus overrides loaded here to be after the above leaflet css so it overrides!
require '../styles/leaflet.styl'

#require 'angular-leaflet-directive'

appName = 'rmapsapp'

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
  'validation'
  'validation.rule'
  'ngImgCrop'
]

app.controller 'rmapsAppController', ($scope, $rootScope, rmapsprincipal) ->

  rmapsprincipal.getIdentity().then (identity) ->
    return unless identity
    {user, profiles} = identity
    user.full_name = if user.first_name and user.last_name then "#{user.first_name} #{user.last_name}" else ""
    user.name = user.full_name or user.username

    _.extend $rootScope,
      user: user
      profiles: profiles

['1','2'].forEach (num) ->
  require("./controllers/mayday_controllers#{num}.coffee")(app)

module.exports = app
