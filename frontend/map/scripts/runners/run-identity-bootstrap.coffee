app = require '../app.coffee'

app.run (rmapsPrincipalService) ->
  #bootstrap the idenitity check when the app loads
  rmapsPrincipalService.getIdentity()
