'use strict'
window.$ = window.jQuery = require 'jquery'
require 'angular'
require 'angular-route'
require 'angular-cookies'
require 'angular-resource'
require 'angular-route'
require 'angular-bootstrap/ui-bootstrap-tpls.js' #angular-bootstrap
#require 'angular-google-maps'
_ = require 'lodash'

require 'bootstrap/dist/css/bootstrap.css'
require 'bootstrap/dist/js/bootstrap.js'

require '../styles/common.css'
require '../../common/extensions/strings.coffee'

#console.log "ANGULAR: #{_.keys(angular)}"

appName = 'app'.ourNs()
console.info "AppName: #{appName}"

app = window.angular.module appName, ['ngCookies', 'ngResource', 'ngRoute', 'ui.bootstrap']

module.exports = app
