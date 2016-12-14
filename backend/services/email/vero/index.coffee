veroBootstrap = require('./service.email.impl.vero.bootstrap')

module.exports = veroBootstrap.then (vero) ->
  events: require('./service.email.impl.vero.events')(vero)
  vero: vero
