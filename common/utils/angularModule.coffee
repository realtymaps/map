###globals _###
'use strict'

if window?.angular?
  require '../extensions/strings.coffee'
  require '../extensions/angular.coffee'

  commonUtilsModule = window.angular.module 'rmapsCommonUtils', []

  module.exports = commonUtilsModule
