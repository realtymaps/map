###globals _###
'use strict'

#
# Create the Angular Module
#
if window?.angular?
  require '../extensions/strings.coffee'
  require '../extensions/angular.coffee'

  # Define and export the Common Utils Module
  commonUtilsModule = window.angular.module 'rmapsCommonUtils', []
  module.exports = commonUtilsModule

  #
  # Forcibly require util files that need to be available for Angular injection
  # Since Browserify will not pick them up if not required at least once
  #
  require('./util.bounds.coffee')

