'use strict'

require '../../../common/extensions/strings.coffee'


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
]

module.exports = app
