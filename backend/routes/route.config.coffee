logger = require '../config/logger'
config = require '../config/config'

module.exports =
  mapboxKey: (req, res, next) ->
    logger.info "mapboxKey requested"
    key = config.MAPBOX.API_KEY
    res.send key
