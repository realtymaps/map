###
 Object list of the defined routes. It's purpose is to keep the
  frontend and backend
###
module.exports =
  index: '/'
  limits: "/limits"
  userPermissions: '/user_permissions/:id'
  groupPermissions:'/group_permissions/:id'
  logIn: '/login'
  logOut: '/logout'
  version: "/version"
  environmentSettings: '/environment_settings/'
