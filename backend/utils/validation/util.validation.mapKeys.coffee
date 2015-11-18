_ = require 'lodash'
Promise = require 'bluebird'
DataValidationError = require '../errors/util.error.dataValidation'
logger  = require '../../config/logger'

# Goal remap the keys of an object
# example:
# options:
#   id:       'user_project.id'
#   notes_id: 'user_notes.id'
#
# req.query =
#  id: 1
#  notes_id: 3
#
# Post transform:
#
# New Object:
#
#  'user_project.id': 1
#  'user_notes.id': 3
# Returns the mapped object.
module.exports = (options = {}) ->
  # console.log "validation.mapKeys options #{JSON.stringify options}"
  (param, value) -> Promise.try () ->
#    logger.debug "begin validation.mapKeys"
    if !options?
      return Promise.reject new DataValidationError("no options provided, options are: #{JSON.stringify(options)}", param, value)

    reMapped = {}
#    logger.debug options
    for key, val of options
      origVal = value[key]
      reMapped[val] = origVal
#    logger.debug reMapped
#    logger.debug "end validation.mapKeys"
    reMapped
