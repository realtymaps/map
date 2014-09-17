###
Object list of the defined routes. It's purpose is to keep the
frontend and backend
###
resource =
  county: 'county'
  mls: 'mls'

module.exports =
  index:                     '/'
  limits:                    '/limits'
  userPermissions:           '/user_permissions/:id'
  groupPermissions:          '/group_permissions/:id'
  logIn:                     '/login'
  logOut:                    '/logout'
  version:                   '/version'
  environmentSettings:       '/environment_settings/'
  #properties
  county:
    root:                    "/#{resource.county}/"
    addresses:               "/#{resource.county}/addresses/"
    apn:                     "/#{resource.county}/apn/"

  mls:
    root:                    "/#{resource.mls}/"
