'use strict'

require '../../../common/extensions/strings.coffee'

appName = 'adminapp'.ourNs()

app = window.angular.module appName, [
  'logglyLogger.logger'
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
