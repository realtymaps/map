{userData} = require '../../../config/tables'
{externalAccounts} = userData
logger = require '../../../config/logger'
Heroku = require 'heroku-client'
{singleRow} = require '../../util.sql.helpers'
encryptor = require '../../../config/encryptor'
_ = require 'lodash'

getHerokuCreds = () ->
  q = externalAccounts().where(name:'heroku')
  singleRow q

restart = (appName = 'realtymaps-map') ->
  getHerokuCreds().then (creds) ->
    if !creds?.api_key?
      logger.error "Critical Error cannot restart heroku with no credentials".
      process.exit(1)

    for key, val of _.omit creds, ['id', 'other', 'name']
      if val?
        creds[key] = encryptor.decrypt val

    logger.debug "Trying to Cycle All Dynos"
    heroku = new Heroku(token: creds.api_key)
    heroku.apps(appName).dynos().restartAll (err) ->
      if err
        logger.error "Heroku Restart Error: #{err}"
      logger.debug "Cycled All Dynos Finished!"
      process.exit(0)


restart()
