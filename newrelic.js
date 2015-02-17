var config = require('./backend/config/config');
var api_key = config.NEW_RELIC.API_KEY;
var appName, instanceName = '';

if(!config.NEW_RELIC.IS_ALLOWED) return;

if(!api_key)
  throw("NEWRELIC_API_KEY not defined! Please add it to your HEROKU APP's ENV VARS");

if(!config.NEW_RELIC.APP_NAME)
  throw("config.NEW_RELIC.APP_NAME not defined!");

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
  app_name : [config.NEW_RELIC.APP_NAME],
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
