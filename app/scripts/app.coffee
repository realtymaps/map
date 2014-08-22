'use strict'
window.$ = window.jQuery = require 'jquery'
window._ = require 'lodash'
require 'ns2'

require 'angular'
require 'angular-route'
require 'angular-ui-router'
require 'angular-cookies'
require 'angular-resource'
require 'angular-route'
require 'angular-bootstrap/ui-bootstrap-tpls.js' #angular-bootstrap
require 'angular-google-maps'
require 'angular-state-files'


require 'bootstrap/dist/css/bootstrap.css'
require 'bootstrap/dist/js/bootstrap.js'

require '../styles/common.scss'
require '../../common/extensions/strings.coffee'

#console.log "ANGULAR: #{_.keys(angular)}"

appName = 'app'.ourNs()
console.info "AppName: #{appName}"

#ns() ~ ui-gmap ~ uiGmap
app = window.angular.module appName, [
  'google-maps'.ns()
  'ngCookies'
  'ngResource'
  'ngRoute'
  'ui.bootstrap'
  'stateFiles'
  'ui.router'
]

module.exports = app
