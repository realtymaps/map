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
  wildcard:             "#{apiBase}/*"

  limits:               "#{apiBase}/limits"
  identity:             "#{apiBase}/identity"
  updateState:          "#{apiBase}/identity/state"
  userPermissions:      "#{apiBase}/user_permissions/:id"
  groupPermissions:     "#{apiBase}/group_permissions/:id"
  login:                "#{apiBase}/login"
  logout:               "#{apiBase}/logout"
  version:              "#{apiBase}/version"
  environmentSettings:  "#{apiBase}/environment_settings/"
  
  # new properties routes
  filterSummary:        "#{apiBase}/properties/filter_summary/"
  parcelBase:           "#{apiBase}/properties/parcel_base/"
  propertyDetails:      "#{apiBase}/properties/property_details/" # not yet set up or fully specified
