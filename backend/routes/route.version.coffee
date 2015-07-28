logger = require '../config/logger'
pack = require '../../package.json'

version =
  app: pack.name
  version: pack.version
versionJSON = JSON.stringify version
# logger.debug 'version: ' + versionJSON

module.exports =
  version: (req, res, next) ->
    # logger.info "sending version info: #{versionJSON}"
    res.send version
