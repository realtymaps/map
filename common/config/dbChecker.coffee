config = require '../../backend/config/config'
unless  window?
  logger = require '../../backend/config/logger'
else
  logger = console

module.exports = ->
if not config.USER_DB.connection or not config.PROPERTY_DB.connection
  logger.error 'Did you use FOREMAN?'
  logger.error 'Database connection strings required! fatal and exiting!'
  process.exit 1
  return
