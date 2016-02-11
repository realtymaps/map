Promise = require 'bluebird'
externalAccounts = require '../../service.externalAccounts'
{CriticalError} = require '../../../utils/errors/util.errors.critical'
exitCodes = require '../../../enums/enum.exitCodes'
logger = require('../../../config/logger').spawn('vero')
{EMAIL_PLATFORM} = require '../../../config/config'
veroFactory = require 'vero-promise'


VeroBootstrap = do () ->
  Promise.try () ->
    externalAccounts.getAccountInfo('vero')
    .then ({other}) ->
      API_KEYS = other
      throw new CriticalError('vero API_KEYS intialization failed.') unless other
      vero = veroFactory(API_KEYS.auth_token)
      logger.debug 'vero initialized'
      vero
  .catch (err) ->
    logger.error "CRITICAL ERROR: OUR EMAIL PLATFORM IS NOT SETUP CORRECTLY"
    logger.error err.stack || err
    if EMAIL_PLATFORM.LIVE_MODE
      #TODO: Send EMAIL to dev team
      logger.debug 'email to dev team: initiated'
    process.exit exitCodes.EMAIL_INIT

module.exports = VeroBootstrap
