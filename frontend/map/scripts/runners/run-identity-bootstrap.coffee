app = require '../app.coffee'

app.run (rmapsprincipal) ->
  #bootstrap the idenitity check when the app loads
  rmapsprincipal.getIdentity()
