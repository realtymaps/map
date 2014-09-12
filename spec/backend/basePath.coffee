path = require 'path'
module.exports = path.join __dirname, '../../backend'
require '../../common/extensions/strings'

after () ->
  return require("#{module.exports}/config/dbs").shutdown()
