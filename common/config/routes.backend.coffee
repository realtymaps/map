###
Object list of the defined routes. It's purpose is to keep the
frontend and backend in sync
###

apiBase = '/api'


module.exports =
  wildcard:
    frontend:        "/*"
    backend:         "#{apiBase}/*"
  user:
    identity:        "#{apiBase}/identity"
    updateState:     "#{apiBase}/identity/state"
    login:           "#{apiBase}/login"
    logout:          "#{apiBase}/logout"
  version:
    version:         "#{apiBase}/version"
  properties:
    filterSummary:   "#{apiBase}/properties/filter_summary/"
    parcelBase:      "#{apiBase}/properties/parcel_base/"
    detail:          "#{apiBase}/properties/detail/" # not yet set up or fully specified
  snail:
    quote:            "#{apiBase}/snail/quote"
    send:             "#{apiBase}/snail/send"
