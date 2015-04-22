logger = require '../config/logger'
config = require '../config/config'

module.exports =
  mapboxKey: (req, res, next) ->
    logger.info "mapboxKey requested"
    key = config.MAPBOX.LIVE_API_KEY or config.MAPBOX.TEST_API_KEY
    res.send key
