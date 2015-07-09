{auth_group_permissions} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
module.exports = routeCrud(auth_group_permissions)
