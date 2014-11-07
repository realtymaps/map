###
Object list of the defined routes. It's purpose is to keep the
frontend and backend
###
resource =
  county: 'county'
  mls: 'mls'

module.exports =
  index:                     '/'
  logInForm:                 '/login'
  limits:                    '/api/limits'
  userPermissions:           '/api/user_permissions/:id'
  groupPermissions:          '/api/group_permissions/:id'
  logIn:                     '/api/login'
  logOut:                    '/api/logout'
  version:                   '/api/version'
  environmentSettings:       '/api/environment_settings/'
  #properties
  county:
    root:                    "/api/#{resource.county}/"
  mls:
    root:                    "/api/#{resource.mls}/"
  wildcard:                  '/*'
