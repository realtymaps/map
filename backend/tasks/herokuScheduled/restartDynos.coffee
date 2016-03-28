logger = require '../../config/logger'
Heroku = require 'heroku-client'
externalAccounts = require '../../services/service.externalAccounts'
shutdown = require '../../config/shutdown'

restart = (appName = 'realtymaps-map') ->
  externalAccounts.getAccountInfo('heroku')
  .then (creds) ->
    if !creds?.api_key?
      logger.error 'Critical Error cannot restart heroku with no credentials'.
      shutdown.exit(error: true)

    logger.debug 'Trying to Cycle All Dynos'
    heroku = new Heroku(token: creds.api_key)
    heroku.apps(appName).dynos().restartAll (err) ->
      if err
        logger.error "Heroku Restart Error: #{err}"
      logger.debug 'Cycled All Dynos Finished!'
      shutdown.exit()


restart()
