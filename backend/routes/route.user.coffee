{user} = require '../services/services.user'
{RouteCrud, hasManyRouteCrud} = require '../utils/crud/util.crud.route.helpers'
logger = require '../config/logger'

class UserCrud extends RouteCrud
  init: () ->
    @permissionsCrud = hasManyRouteCrud(@svc.permissions, 'permission_id', 'user_id')
    @permissions = @permissionsCrud.root
    @permissionsById = @permissionsCrud.byId

    @groupsCrud = hasManyRouteCrud(@svc.groups, 'group_id', 'user_id')#.init(true)#to enable logging
    @groups = @groupsCrud.root
    @groupsById = @groupsCrud.byId

    @profilesCrud = hasManyRouteCrud(@svc.profiles, 'profile_id', 'auth_user_id')
    @profiles = @profilesCrud.root
    @profilesById = @profilesCrud.byId
    super()

module.exports = new UserCrud(user)
