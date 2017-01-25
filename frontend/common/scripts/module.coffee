require 'angular/angular'
require 'angular-simple-logger'
require 'angular-ui-router'
require 'spinkit/css/spinkit.css'
require 'font-awesome/css/font-awesome.css'
require 'ui-select'
require 'ui-select/dist/select.css'
require 'angular-validation/dist/angular-validation.js'
require 'angular-validation/dist/angular-validation-rule.js'


# maybe later on angular-extend-promises
# their .each is buggy and does not pass bluebird specs
# lastly the module is difficult to import '../tmp/lodash' must be replaced everywhere
# see: https://bitbucket.org/lsystems/angular-extend-promises/issues/3/how-do-you-import-this-library-via-commnjs
# window._ = require('lodash')
# if !window._.functionsIn?
#   window._.functionsIn = window._.methods
# if !window._.object?
#   window._.zipObjecy = window._.object

# require('angular-extend-promises/src/index.js')


mod = window.angular.module 'rmapsCommon', [
  'nemLogging'
  'ui.router'
  'ui.select'
  'validation'
  'validation.rule'
  # 'angular-extend-promises'
]

module.exports = mod
