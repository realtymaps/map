###global _:true###
app = require '../app.coffee'

module.exports = app.constant 'rmapsRouteIdentityResolve', (rmapsPrincipalService) ->
  return rmapsPrincipalService.getIdentity()
