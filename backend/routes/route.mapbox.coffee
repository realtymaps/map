logger = require '../config/logger'
validation = require '../utils/util.validation'
{uploadParcel} = require '../services/service.mapbox.parcels'

module.exports =
  upload: (req, res, next) ->
    uploadParcel(req.session.state, req.query)
    .then (stream) ->
      # stream.pipe res
      res.send('success')
    .catch validation.DataValidationError, (err) ->
      next new ExpressResponse(alert: {msg: err.message}, httpStatus.BAD_REQUEST)
    .catch (err) ->
      logger.error err.stack||err.toString()
      next(err)
