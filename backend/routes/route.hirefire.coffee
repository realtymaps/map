logger = require('../config/logger').spawn('hirefire')
ExpressResponse = require '../utils/util.expressResponse'
hirefire = require '../services/service.hirefire'


info = (req, res, next) ->
  hirefire.getQueueNeeds()
  .then (needs) ->
    next new ExpressResponse(needs)
  .catch (err) ->
    logger.error "unexpected error during hirefire info check: #{err.stack||err}"
    next(err)


module.exports =
  info: info
