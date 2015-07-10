{auth_user_groups} = require '../services/services.user'
{routeCrud} = require '../utils/crud/util.crud.route.helpers'
module.exports = routeCrud(auth_user_groups)
