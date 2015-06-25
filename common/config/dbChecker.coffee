config = require '../../backend/config/config'
unless  window?
  logger = require '../../backend/config/logger'
else
  logger = console

module.exports = ->
if (not config.USER_DB.connection or not config.PROPERTY_DB.connection) and
    !process.env.IS_HEROKU
  logger.error 'Did you use FOREMAN?'
  logger.error 'Database connection strings required! fatal and exiting!'
  require('../../backend/config/dbs').shutdown()
  process.exit 1
