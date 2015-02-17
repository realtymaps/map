module.exports = (environment) ->
  canRunNewRelic = environment != 'development'
  API_KEY: process.env.NEW_RELIC_API_KEY
  maybeLoad: ->
    require('newrelic') if canRunNewRelic
  IS_ALLOWED: canRunNewRelic
  APP_NAME: do ->
    #should this be in newrelic.js seems like a lot of responsibility for this file
    appName = 'realtymaps-map'
    return appName if environment == 'production'

    instanceName = process.env.INSTANCE_NAME
    instanceName += '-' if instanceName?

    ###
      We should possibly throw and exit the application if instanceName is null/undefined here.
    This way we can avoid duplicate staging apps in the APM manager of New Relic
    otherwise this will become a maintenance hell.

    Also developers should limit their staging to 1 Dyno of the smallest size too keep cost down.
    Especially if New Relic is pinging it often.


    Maintenance (new relic):
      FYI to delete the app you need to have OWNER heroku privileges and the Heroku app must be shut down
      it takes a few minutes for New Relic to decide that it is down (GREYED out)
      https://docs.newrelic.com/docs/apm/new-relic-apm/maintenance/removing-applications-servers#ui-settings
    ###
    unless instanceName
      msg = "INSTANCE_NAME not defined! Please add it to your HEROKU APP's ENV VARS"
      console.error msg
      throw msg
    appName = instanceName + 'staging-' + appName