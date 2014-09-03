# we have to combine these 3 models into 1 file because they all mutually call
# each other; node can handle circular dependencies of a certain form, but the
# way we're returning our modules within closures makes that impossible  

module.exports = (app) ->

  result = {}
  
  result.User = app.dbs.users.Model.extend
    tableName: "auth_user"
    groups: () ->
      @belongsToMany(result.Group, "auth_user_groups", "user_id", "group_id")
    permissions: () ->
      @belongsToMany(result.Permission, "auth_user_user_permissions", "user_id", "permission_id")
  result.Permission = app.dbs.users.Model.extend
    tableName: "auth_permission",
    users: () ->
      @belongsToMany(result.User, "auth_user_user_permissions", "permission_id", "user_id")
    groups: () ->
      @belongsToMany(result.Group, "auth_group_permissions", "permission_id", "group_id")
  result.Group = app.dbs.users.Model.extend
    tableName: "auth_group",
    users: () ->
      @belongsToMany(result.User, "auth_user_groups", "group_id", "user_id")
    permissions: () ->
      @belongsToMany(result.Permission, "auth_group_permissions", "group_id", "permission_id")

  return result
