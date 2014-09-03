logger = require '../config/logger'
_ = require("lodash")

hashifyPermissions = (hash, permission) ->
  hash[permission.codename] = true;
  return hash

module.exports = (app) ->
  UserPermissionModels = require("../models/userPermissionModels")(app)
  
  return {
    getPermissionsForUserId: (id, callback) ->
      new UserPermissionModels.User(id: id).fetch(withRelated: ['permissions', 'groups.permissions'])
        .then (user) ->
          # transform the bookshelf object into a simple object
          user = user.toJSON()
          
          # we want to reformat this data as a hash of codenames to truthy values
          permissionsHash = {}
          
          if user.is_superuser
            # just give them all the permissions
            UserPermissionModels.Permission.fetchAll()
              .then (permissions) ->
                _.reduce(permissions.toJSON(), hashifyPermissions, permissionsHash)
                process.nextTick () ->
                  callback(null, permissionsHash)
          else
            # first grab the permissions on each group
            _.forEach user.groups, (group) ->
              _.reduce(group.permissions, hashifyPermissions, permissionsHash)
            # then the permissions on the user
            _.reduce(user.permissions, hashifyPermissions, permissionsHash)
            process.nextTick () ->
              callback(null, permissionsHash)
        .catch(() -> process.nextTick(callback))
  }
