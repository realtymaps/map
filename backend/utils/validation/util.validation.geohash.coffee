Promise = require "bluebird"
geohash64 = require 'geohash64'
DataValidationError = require './util.error.dataValidation'
logger = require '../../config/logger'

module.exports = (param, boundsStr) ->
  Promise.try () ->
    hash = geohash64.decode(boundsStr)
#    logger.debug 'hash'
#    logger.debug hash, true
    hash
  .catch (err) ->
    Promise.reject new DataValidationError("error decoding geohash string", param, boundsStr)
