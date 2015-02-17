var config = require('./backend/config/config');
var api_key = config.NEW_RELIC.API_KEY;
var appName = config.NEW_RELIC.APP_NAME;

if(!api_key)
  throw("NEWRELIC_API_KEY not defined! Please add it to your Heroku app's config vars or your .env file.");

if(!appName)
  throw("config.NEW_RELIC.APP_NAME not defined! Please define INSTANCE_NAME in your Heroku app's config vars or your .env file.");

/**
 * New Relic agent configuration.
 *
 * See lib/config.defaults.js in the agent distribution for a more complete
 * description of configuration variables and their potential values.
 */
exports.config = {
  /**
   * Array of application names.
   */
  app_name : [appName],
  /**
   * Your New Relic license key.
   */
  license_key : api_key,
  logging : {
    /**
     * Level at which to log. 'trace' is most useful to New Relic when diagnosing
     * issues with the agent, 'info' and higher will impose the least overhead on
     * production applications.
     */
    level : 'debug'
  }
};
