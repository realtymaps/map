app = require '../app.coffee'

app.run ["principal".ourNs(), (principal) ->
  #bootstrap the idenitity check when the app loads
  principal.getIdentity()
]
