{auth_group} = require '../services/services.user'
crudRoute = require '../utils/crud/util.crud.route.helpers'
module.exports = crudRoute.streamCrud(auth_group)
