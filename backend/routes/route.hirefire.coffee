logger = require('../config/logger').spawn('hirefire')
ExpressResponse = require '../utils/util.expressResponse'
hirefire = require '../services/service.hirefire'


info = (req, res, next) ->
  result = null
  hirefire.getQueueNeeds()
  .then (needs) ->
    result = new ExpressResponse(needs)
  .catch (err) ->
    logger.error "unexpected error during hirefire info check: #{err.stack||err}"
    result = err
  .finally () ->
    next(result)


module.exports =
  info: info
