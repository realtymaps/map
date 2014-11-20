###
Object list of the defined routes. It's purpose is to keep the
frontend and backend
###
keysToValue = require '../utils/util.keys_to_values.coffee'

resource = keysToValue
  county: undefined
  mls: undefined
  parcels: undefined

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
  parcels:
    root:                    "#{apiBase}/#{resource.parcels}/"
    polys:                   "#{apiBase}/#{resource.parcels}/polys/"