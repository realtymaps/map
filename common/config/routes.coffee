###
Object list of the defined routes. It's purpose is to keep the
frontend and backend
###
resource =
  county: 'county'
  mls: 'mls'

apiBase = '/api'

module.exports =
  apiWildcard:               "#{apiBase}/*"
  wildcard:                  "/*"

  index:                     '/'
  logInForm:                 '/login'
  
  limits:                    "#{apiBase}/limits"
  userPermissions:           "#{apiBase}/user_permissions/:id"
  groupPermissions:          "#{apiBase}/group_permissions/:id"
  logIn:                     "#{apiBase}/login"
  logOut:                    "#{apiBase}/logout"
  version:                   "#{apiBase}/version"
  environmentSettings:       "#{apiBase}/environment_settings/"
  #properties
  county:
    root:                    "#{apiBase}/#{resource.county}/"
  mls:
    root:                    "#{apiBase}/#{resource.mls}/"
