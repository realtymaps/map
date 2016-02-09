config = require './config'

if config.NEW_RELIC.RUN
  module.exports = require 'newrelic'
else
  module.exports =
    getBrowserTimingHeader: () ->
      '<!-- NEWRELIC NOT LOADED -->'
