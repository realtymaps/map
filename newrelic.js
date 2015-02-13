var api_key = process.env.NEWRELIC_LIVE_API_KEY;
var appName, instanceName = '';
if(process.env.NODE_ENV === 'development') return;

if(process.env.NODE_ENV !== 'production'){
  api_key = process.env.NEWRELIC_STAGING_API_KEY;
  if(!api_key){
    throw("NEWRELIC_STAGING_API_KEY not defined! Please add it to your HEROKU APP's ENV VARS");
    return;
  }
  instanceName = process.env.INSTANCE_NAME;
  if(instanceName !== null || instanceName !== undefined)
    instanceName += '-';
  //we should possibly throw and exit the application if instanceName is null/undefined here
  //this way we can avoid duplicate staging apps in the APM manager of newrelic
  //otherwise this will become a maintance hell
  // FYI to delete the app you need to have OWNER heroku privledges and the heroku app must be shut down
  // it takes a few minutes for NEWRELIC to decide that it is down (GREYED out)
  // https://docs.newrelic.com/docs/apm/new-relic-apm/maintenance/removing-applications-servers#ui-settings
  if(!instanceName){
      throw("INSTANCE_NAME not defined! Please add it to your HEROKU APP's ENV VARS");
    return;
  }
  appName = instanceName + 'staging-';
}

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
  app_name : [appName + 'realtymaps-map'],
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
