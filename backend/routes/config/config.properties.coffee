auth = require '../../utils/util.auth'
userSessionService = require '../../services/service.userSession'

module.exports =
  filterSummary:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapFilterState
    ]
  parcelBase:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapState
    ]
  addresses:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapState
    ]
  detail:
    middleware: [
      auth.requireLogin(redirectOnFail: true)
      userSessionService.captureMapState
    ]
