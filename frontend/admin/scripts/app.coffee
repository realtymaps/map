'use strict'

require '../../../common/extensions/strings.coffee'

appName = 'adminapp'.ourNs()

app = window.angular.module appName, [
  'logglyLogger.logger'
]

module.exports = app
