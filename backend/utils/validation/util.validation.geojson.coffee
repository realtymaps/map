Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
gjv = require 'geojson-validation'
logger = require('../../config/logger').spawn('validation:geojson')
{crsFactory} = require '../../../common/utils/enums/util.enums.map.coord_system'

module.exports = (options = {}) ->
  (param, value) -> Promise.try () ->
    logger.debug.green 'running validation.geojson'
    logger.debug.cyan "original val"
    logger.debug value, true
    logger.debug.green "options"
    logger.debug options, true

    if !value? or value == ''
      return null
    if !gjv.valid(value)
      return Promise.reject new DataValidationError('invalid data for geojson field', param, value)
    if options?.crs? and !value.crs
      return Promise.reject new DataValidationError('invalid data for geojson.crs field missing', param, value)

    if options?.toCrs?
      logger.debug 'toCrs'
      value.crs = crsFactory(options.toCrs)

    logger.debug.cyan "transformed"
    logger.debug value, true
    return value
