path = require 'path'

basePath = path.join __dirname, '../../backend'
commonPath = path.join __dirname, '../../common'


before ->


after ->
  return require("#{basePath}/config/dbs").shutdown()


module.exports = {basePath, commonPath}
