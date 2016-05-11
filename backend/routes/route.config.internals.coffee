config = require '../config/config'


# if safe config becomes more complicated we may want to make this memoizee function
# NOTE: NEVER send over the whole config object as many field values should not be exposed
safeConfig =
  ANGULAR: config.ANGULAR
  debugLevels: config.LOGGING.ENABLE

module.exports = {
  safeConfig
}
