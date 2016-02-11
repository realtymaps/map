path = require 'path'
module.exports = path.join __dirname, '../../backend'


before ->


after ->
  return require("#{module.exports}/config/dbs").shutdown()
