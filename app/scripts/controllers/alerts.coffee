app = require '../app.coffee'

module.exports = app.controller 'AlertsCtrl'.ourNs(), [
  '$scope', '$timeout', 'events'.ourNs(), 'MainOptions'.ourNs(), '$interval',
  ($scope, $timeout, Events, MainOptions, $interval) ->
    $scope.alerts = []
    alertsMap = {}
    anonymousAlertCounter = 1
    
    # when we hide an alert, we don't want to completely get rid of it -- we want to keep it around so we know not to
    # show similar alerts for a while.
    $scope.hideAlert = (alertId) ->
      alert = alertsMap[alertId]
      # if it has already been removed or closed, don't do anything
      if !alert? || alert.closed
        return
      # mark it as closed
      alert.closed = true
      # remove it from the display array
      index = $scope.alerts.indexOf(alert)
      $scope.alerts.splice(index, 1);
      # cancel any existing expiration timeout, and set a new one based on the quiet period
      $timeout.cancel(alert.expiration)
      alert.expiration = $timeout(removeAlert.bind(null, alert.id), alert.quietMillis)
    
    # this is what we call to remove a still-visible alert after a timeout, or to reset a closed alert so we can start
    # showing it again
    removeAlert = (alertId) ->
      alert = alertsMap[alertId]
      console.log("@@@@@@@@@@@@@@@ removeAlert: #{JSON.stringify(alert,null,2)}")
      # if it has already been removed, don't do anything
      if !alert?
        return
      # if it hasn't been closed, we also need to remove it from the display array
      if !alert.closed
        index = $scope.alerts.indexOf(alert)
        $scope.alerts.splice(index, 1);
      # this makes us forget it ever happened
      delete alertsMap[alertId]
    
    # this handles an incoming alert that is intended to override an existing one
    handleDupeAlert = (alert) ->
      # copy over all values, just in case something has escalated or changed
      _.extend(alertsMap[alert.id], alert)
      alert = alertsMap[alert.id]
      if !alert.closed
        newDelay = alert.ttlMillis
        # increment the repetition counter
        alert.reps++
        # move this alert to the end of the list
        index = $scope.alerts.indexOf(alert)
        $scope.alerts.splice(index, 1);
        $scope.alerts.push(alert)
      else
        newDelay = alert.quietMillis
      # cancel any existing expiration timeout, and set a new one based on either the ttl or the quiet period 
      $timeout.cancel(alert.expiration)
      alert.expiration = $timeout(removeAlert.bind(null, alert.id), newDelay)
      
    # this handles a new (or expired/forgotten) alert
    handleNewAlert = (alert) ->
      # give a unique id to alerts that don't have one (i.e. alerts that can't be dupes)
      if !alert.id?
        alert.id = "__alert_#{anonymousAlertCounter++}__"
      # set some default values
      alert.reps = 0
      if !alert.ttlMillis?
        alert.ttlMillis = MainOptions.alert.ttlMillis
      if !alert.quietMillis?
        alert.quietMillis = MainOptions.alert.quietMillis
      # set a timeout to remove the alert
      alert.expiration = $timeout(removeAlert.bind(null, alert.id), alert.ttlMillis)
      # put it in the display list and map
      $scope.alerts.push(alert)
      alertsMap[alert.id] = alert
      
    # this detects incoming alerts and passes them off for handling
    $scope.$onRootScope Events.alert, (event, alert) ->
      console.log("@@@@@@@@@@@@@@@ handle: #{JSON.stringify(alert,null,2)}")
      if !alert.id? || !alertsMap[alert.id]
        handleNewAlert(alert)
      else
        handleDupeAlert(alert)
]
