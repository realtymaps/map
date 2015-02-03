Promise = require "bluebird"
geohash64 = require 'geohash64'
ParamValidationError = require './util.error.paramValidation'


module.exports = (param, boundsStr) ->
  Promise.try () ->
    geohash64.decode(boundsStr)
  .catch (err) ->
    Promise.reject new ParamValidationError("error decoding geohash string", param, boundsStr)
