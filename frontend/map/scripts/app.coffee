'use strict'

require '../../../common/extensions/strings.coffee'


#Wierd this does not work well render problems.. bower is fine
require '../../../bower_components/leaflet-plugins/layer/tile/Google.js'
require '../../../bower_components/leaflet/dist/leaflet.css'
require '../../../bower_components/leaflet.markercluster/dist/MarkerCluster.Default.css'
require '../../../bower_components/leaflet.markercluster/dist/MarkerCluster.css'
require '../../../bower_components/leaflet.zoombox/L.Control.ZoomBox.js'
require '../../../bower_components/leaflet.zoombox/L.Control.ZoomBox.css'
#leaflet stylus overrides loaded here to be after the above leaflet css so it overrides!
require '../styles/leaflet.styl'

#require 'angular-leaflet-directive'

appName = 'app'.ourNs()
#console.info "AppName: #{appName}"

app = window.angular.module appName, [
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
]

module.exports = app
