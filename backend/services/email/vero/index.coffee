veroBootstrap = require('./service.email.impl.vero.bootstrap')
logger = require('../../../config/logger').spawn('vero')

module.exports = veroBootstrap.then (vero) ->
  logger.debug(vero)
  user: require('./service.email.impl.vero.user')(vero)
  events: require('./service.email.impl.vero.events')(vero)
  vero: vero
