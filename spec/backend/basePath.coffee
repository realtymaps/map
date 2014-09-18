path = require 'path'
module.exports = path.join __dirname, '../../backend'
global.sinon = require 'sinon'
global._ = require 'lodash'
require '../../common/extensions/strings'

before ->


after ->
  return require("#{module.exports}/config/dbs").shutdown()
