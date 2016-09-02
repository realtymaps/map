defaultConf = require './karma.conf'
module.exports = (config) ->
  defaultConf {
    set: (conf) ->
      conf.autoWatch = true
      conf.singleRun = false
      conf.logLevel = config.LOG_INFO
      console.log conf
      conf

      config.set conf
  }
