Promise = require 'bluebird'
externalAccounts = require '../../service.externalAccounts'
{CriticalError} = require '../../../utils/errors/util.errors.critical'
logger = require('../../../config/logger').spawn('vero')
{EMAIL_PLATFORM} = require '../../../config/config'
veroFactory = require 'vero-promise'
shutdown = require '../../../config/shutdown'
analyzeValue = require '../../../../common/utils/util.analyzeValue'


VeroBootstrap = do () ->
  Promise.try () ->
    externalAccounts.getAccountInfo('vero')
    .then ({other}) ->
      API_KEYS = other
      if !API_KEYS?.auth_token
        throw new CriticalError('vero API_KEYS intialization failed.')
      vero = veroFactory(API_KEYS.auth_token)
      logger.debug "Vero initialized with auth_token"
      logger.debug(vero)
      vero
  .catch (err) ->
    logger.error "CRITICAL ERROR: OUR EMAIL PLATFORM IS NOT SETUP CORRECTLY"
    logger.error analyzeValue.getFullDetails(err)
    if EMAIL_PLATFORM.LIVE_MODE
      #TODO: Send EMAIL to dev team
      logger.debug 'email to dev team: initiated'
    shutdown.exit(error: true)

module.exports = VeroBootstrap
