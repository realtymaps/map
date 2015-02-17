var config = require('./backend/config/config');
var api_key = config.NEW_RELIC.API_KEY;
var appName = config.NEW_RELIC.APP_NAME;

if(!api_key)
  throw("NEWRELIC_API_KEY not defined! Please add it to your Heroku app's config vars or your .env file.");

if(!appName)
  throw("config.NEW_RELIC.APP_NAME not defined! Please define INSTANCE_NAME in your Heroku app's config vars or your .env file.");

/*
We use a different INSTANCE_NAME for each staging/dev instance, that way we can avoid duplicate apps in the APM manager
of New Relic -- otherwise this would become a maintenance hell.

Developers should limit their staging to 1 Dyno of the smallest size to keep cost down, especially when new relic is
pinging the app (whcih will keep it from sleeping).

Maintenance:
  FYI to delete an app from new relic, you need to have OWNER heroku privileges and the Heroku app must be shut down
  it takes a few minutes for New Relic to decide that it is down (GREYED out)
  https://docs.newrelic.com/docs/apm/new-relic-apm/maintenance/removing-applications-servers#ui-settings
*/

/**
 * New Relic agent configuration.
 *
 * See lib/config.defaults.js in the new relic lib for a more complete
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
