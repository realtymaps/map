logger = require('../config/logger').spawn('hirefire')
ExpressResponse = require '../utils/util.expressResponse'
hirefire = require '../services/service.hirefire'
analyzeValue = require '../../common/utils/util.analyzeValue'


info = (req, res, next) ->
  result = null
  hirefire.getQueueNeeds()
  .then (needs) ->
    result = new ExpressResponse(needs)
  .catch (err) ->
    logger.error "unexpected error during hirefire info check: #{analyzeValue.getFullDetails(err)}"
    result = err
  .finally () ->
    next(result)


module.exports =
  info: info
