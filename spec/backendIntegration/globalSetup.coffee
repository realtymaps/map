path = require 'path'

basePath = path.join __dirname, '../../backend'
commonPath = path.join __dirname, '../../common'


before ->


after ->
  dbs = require("#{basePath}/config/dbs")
  return dbs.shutdown(quiet: true)


module.exports = {basePath, commonPath}
