webpackConf = require './webpack_karma.conf'
webpackConf.cache = false

should = require 'should'

module.exports = (config) ->
  commonConfig = require('./karma.common')(config,webpackConf)
  config.set commonConfig
