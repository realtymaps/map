tables = require '../config/tables'
userInternals = require './service.user.internals'

upsertImage = (entity, blob) ->
  userInternals.upsertImage(entity,blob, tables.user.company)

module.exports = {
  upsertImage
}
