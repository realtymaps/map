Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
logger = require('../../config/logger').spawn("util:validation:neSwBounds")
_ = require 'lodash'

#http://localhost:4000/api/cartodb/fipscodeFile/12021?api_key=98d64004-be29-4f51-b883-1da478cf8f3d&nesw=[[26.14263870556064,-81.79392099380493],%20[26.13431698705448,-81.80765390396118]]
#string should be an array of [[nelat,nelon],[swlat,swlon]]
module.exports = (param, boundsObjStr) -> Promise.try ->
  logger.debug -> "boundsObjStr: #{boundsObjStr}"
  if !boundsObjStr?
    return null
  logger.debug -> "newSw validator"
  obj = JSON.parse boundsObjStr
  logger.debug -> "isArray: #{_.isArray obj}"
  logger.debug -> "length: #{obj.length}"
  if !_.isArray(obj) or !obj?.length == 2
    throw new DataValidationError("[nesw] bounds format error Obj is not an array or incorrect array length. Obj: #{obj}", param)
  obj
.catch DataValidationError, (err) ->
  throw err
.catch (err) ->
  throw new DataValidationError('Unkown error decoding nesw string', param, err)
