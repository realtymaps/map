config = require '../../../config/config'
errors = require '../../../utils/errors/util.errors.vero'

getUniqueUserId = (authUser) ->
  if !authUser?.id?
    throw new errors.UserIdDoesNotExistError("Cannot get Vero id for user")
  if config.ENV == 'production'
    return "production_#{authUser.id}"
  else
    if config.RMAPS_MAP_INSTANCE_NAME
      return "#{config.RMAPS_MAP_INSTANCE_NAME}_#{config.ENV}_#{authUser.id}"
    else
      throw new Error("Please set RMAPS_MAP_INSTANCE_NAME")

module.exports = {
  getUniqueUserId
}
