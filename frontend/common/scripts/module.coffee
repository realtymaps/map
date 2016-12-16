require('angular/angular')
require('angular-simple-logger')
require('angular-ui-router')
# maybe later on angular-extend-promises
# their .each is buggy and does not pass bluebird specs
# lastly the module is difficult to import '../tmp/lodash' must be replaced everywhere
# see: https://bitbucket.org/lsystems/angular-extend-promises/issues/3/how-do-you-import-this-library-via-commnjs
# require('lodash')
# require('lodash-migrate')#needed for angular-extend-promises
# require('angular-extend-promises/angular-extend-promises-without-lodash.js')


mod = window.angular.module 'rmapsCommon', [
  'nemLogging'
  'ui.router'
]

module.exports = mod
