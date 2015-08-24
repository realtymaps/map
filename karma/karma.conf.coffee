should = require 'should'

module.exports = (config) ->
  commonConfig = require('./karma.common')(config)
  config.set commonConfig
