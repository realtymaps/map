Promise = require 'bluebird'
DataValidationError = require './util.error.dataValidation'
logger = require '../../config/logger'
_ = require 'lodash'

#http://localhost:4000/api/cartodb/fipscodeFile/12021?api_key=98d64004-be29-4f51-b883-1da478cf8f3d&nesw=[[26.14263870556064,-81.79392099380493],%20[26.13431698705448,-81.80765390396118]]
#string should be an array of [[nelat,nelon],[swlat,swlon]]
module.exports = (param, boundsObjStr) -> Promise.try ->
  # logger.debug "boundsObjStr: #{boundsObjStr}"
  throw new Error('neSwBounds Param undefined!') unless boundsObjStr
  # logger.debug "newSw validator"
  obj = JSON.parse boundsObjStr
  # console.debug "isArray: #{_.isArray obj}"
  # console.debug "length: #{obj.length}"
  if !_.isArray(obj) or !obj?.length == 2
    throw new Error("[nesw] bounds format error Obj is not an array or incorrect array length. Obj: #{obj}")
  obj
.catch (err) ->
  Promise.reject new DataValidationError('error decoding nesw string', param, err)
