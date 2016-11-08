###global _:true###
app = require '../app.coffee'

module.exports = app.constant 'rmapsRouteIdentityResolve', (rmapsPrincipalService) ->
  "ngInject"
  return rmapsPrincipalService.getIdentity()
