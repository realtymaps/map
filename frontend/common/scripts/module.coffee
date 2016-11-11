require('angular/angular')
require('angular-simple-logger')
require('angular-ui-router')

mod = window.angular.module 'rmapsCommon', ['nemLogging', 'ui.router']

module.exports = mod
