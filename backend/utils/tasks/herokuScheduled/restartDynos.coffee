tables = require '../../../config/tables'
logger = require '../../../config/logger'
Heroku = require 'heroku-client'
externalAccounts = require '../../../services/service.externalAccounts'
{singleRow} = require '../../util.sql.helpers'
_ = require 'lodash'

restart = (appName = 'realtymaps-map') ->
  externalAccounts.getAccountInfo('heroku')
  .then (creds) ->
    if !creds?.api_key?
      logger.error 'Critical Error cannot restart heroku with no credentials'.
      process.exit(1)

    logger.debug 'Trying to Cycle All Dynos'
    heroku = new Heroku(token: creds.api_key)
    heroku.apps(appName).dynos().restartAll (err) ->
      if err
        logger.error "Heroku Restart Error: #{err}"
      logger.debug 'Cycled All Dynos Finished!'
      process.exit(0)


restart()
