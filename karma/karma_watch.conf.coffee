webpackConf = require './webpack_karma.conf'
#IMPORTANT KEEPS Karma and Webpack playing nice if your watchinf
#otherwise you end up in a infinite loop
webpackConf.cache = true

should = require 'should'

module.exports = (config) ->
  commonConfig = require('./karma.common')(config,webpackConf)
  commonConfig.browsers = ['Chrome']
  commonConfig.autoWatch = true
  config.set commonConfig
