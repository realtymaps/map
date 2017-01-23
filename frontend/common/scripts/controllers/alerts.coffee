#NOTE Some of the comment grammar below is not correct (missing apostrophes) as it is causing problems with
# chromes debugger.

###
# alerts!
# -------
# In addition to alerts that will be automatically spawned based on metadata in API responses, you can create a new
# alert on the frontend by emitting an alert event.  If a given type of alert is spamming (based on id, as explained
# below), then all repetitions will be grouped into 1 alert; if that alert is hidden by the user, it will stay hidden
# as long as the alert keeps spamming, but if it quits spamming for long enough and then starts up again, it will show
# up as a new alert.  Alerts can be programmatically hidden as well.
# -------
# An alert will be shown via the 'main' state view, so they overlay any subviews from 'main' (and thus follow you if you
# change view).  An alert will dismiss itself after a while (there is a default TTL value in MainOptions, which can be
# overriden on a particular event; the special value 0 means not to auto-dismiss), or can be hidden before this by
# clicking the X in the upper-right of the alert.  New alerts that have the same id as an existing alert replace that
# alert, resetting its dismissal timer, moving it to the end of the list, and incrementing its repetition counter,
# similar to how Chromes js console handles repeated console messages.  Once an alert has been hidden by a user, it
# (and any alerts with the same id) will remain hidden; the alert will be dismissed once it has been hidden for a quiet
# period without its repetition counter getting incremented (default value in MainOptions, but can be overriden
# per-event, and 0 is not handled specially unlike TTL).
# -------
# To spawn an event, use:
#   $rootScope.$emit Events.alert.spawn, alertObj
# To hide an event, use:
#   $rootScope.$emit Events.alert.hide, alertId
# To dismiss an event, use:
#   $rootScope.$emit Events.alert.dismiss, alertId
# To preemptively hide an event, use:
#   $rootScope.$emit Events.alert.prevent, {id: alertId, quietMillis: quietTime}
# -------
# Allowed properties of an emitted alert:
#   msg (required): the main body of the alert.  This can be HTML, but should consist only of inline or inline-block
#     type formatting since it is all contained in a span.
#   type: a string that determines the colors used for the alert; defaults to "rm-danger". There are 4 intended values,
#     but this is not enforced; any string passed in this field will be prepended with "alert-" and applied as a class.
#     Styling for the 4 values below is in alerts.styl.  Default (pale) bootstrap versions of the below are available by
#     removing the "rm-" prefix
#       - "rm-danger": vivid red
#       - "rm-warning": vivid yellow-orange
#       - "rm-info": vivid blue
#       - "rm-success": vivid green
#   id: this string is used to identify alerts that should be grouped together as repetitions.  If no value is passed,
#     a value is generated that will not be generated for any other anonymous alert.
#   ttlMillis: milliseconds until a visible alert will auto-dismiss (counted from its most recent repetition); defaults
#     to MainOpions.alerts.ttlMillis
#   quietMillis: milliseconds until a hidden alert will auto-dismiss (counted from its most recent repetition); defaults
#     to MainOpions.alerts.quietMillis
###
mod = require '../module.coffee'
_ = require 'lodash'


mod.controller 'rmapsAlertsCtrl', ($scope, $timeout, $sce, rmapsEventConstants, $log, rmapsMainOptions) ->
  $scope.alerts = []
  alertsMap = {}
  anonymousAlertCounter = 1

  # when we hide an alert, we don't want to completely get rid of it -- we want to keep it around so we know not to
  # show similar alerts for a while.
  hideAlert = (alertId) ->
    alert = alertsMap[alertId]
    # if it has already been removed or closed, don't do anything
    if !alert? || alert.closed
      return
    # mark it as closed
    alert.closed = true
    # remove it from the display array
    index = $scope.alerts.indexOf(alert)
    $scope.alerts.splice(index, 1)
    # cancel any existing expiration timeout, and set a new one based on the quiet period
    if alert.expiration?
      $timeout.cancel(alert.expiration)
    alert.expiration = $timeout(removeAlert.bind(null, alert.id), alert.quietMillis)

  # use this to preemtpively hide an alert that (maybe) hasn't been triggered yet
  preventAlert = (alertInfo) ->
    alert = alertsMap[alertInfo.id]
    # if it exists already, just hide it as normal except use the new quiet time value
    if alert?
      alert.quietMillis = alertInfo.quietMillis
      hideAlert(alertInfo.id)
      return

    alert = _.clone(alertInfo)
    # mark it as closed
    alert.closed = true
    # set an expiration timeout
    alert.expiration = $timeout(removeAlert.bind(null, alert.id), alert.quietMillis)
    # put it in the mapping
    alertsMap[alertInfo.id] = alert

  # this is what we call to remove a still-visible alert after a timeout, or to reset a closed alert so we can start
  # showing it again
  removeAlert = (alertId) ->
    alert = alertsMap[alertId]
    # if it has already been removed, don't do anything
    if !alert?
      return
    # if it hasn't been closed, we also need to remove it from the display array
    if !alert.closed
      index = $scope.alerts.indexOf(alert)
      $scope.alerts.splice(index, 1)
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
      alert.reps += 1
      # move this alert to the end of the list
      index = $scope.alerts.indexOf(alert)
      $scope.alerts.splice(index, 1)
      $scope.alerts.push(alert)
    else
      newDelay = alert.quietMillis
    # cancel any existing expiration timeout, and set a new one based on either the ttl or the quiet period
    if alert.expiration?
      $timeout.cancel(alert.expiration)
    if newDelay > 0 || alert.closed   # quiet period is allowed to be 0, but TTL of 0 means unlimited
      alert.expiration = $timeout(removeAlert.bind(null, alert.id), newDelay)

  # this handles a new (or expired/forgotten) alert
  handleNewAlert = (alert) ->
    # give a unique id to alerts that don't have one (i.e. alerts that can't be dupes)
    if !alert.id?
      alert.id = "__alert_#{anonymousAlertCounter}__"
      anonymousAlertCounter += 1
    # set some default values
    alert.reps = 0
    if !alert.type?
      alert.type = 'rm-danger'
    if !alert.ttlMillis?
      alert.ttlMillis = rmapsMainOptions.alert.ttlMillis
    if !alert.quietMillis?
      alert.quietMillis = rmapsMainOptions.alert.quietMillis
    # set a timeout to remove the alert
    if alert.ttlMillis > 0
      alert.expiration = $timeout(removeAlert.bind(null, alert.id), alert.ttlMillis)
    # put it in the display list and map
    $scope.alerts.push(alert)
    alertsMap[alert.id] = alert

  # this does some common alert handling and then branches based on whether the alert is a dupe
  handleAlertSpawnEvent = (event, alert) ->
    if !alert.msg
      $log.warn "alert received with no message: #{JSON.stringify(alert,null,2)}\n from event: #{JSON.stringify(event,null,2)}"
      return
    # getting these errors to console could help if a user calls and didn't record the error reference -- support can
    # direct them to open the js console and get the error reference there
    $log.warn('Alert message: '+(if alert.id? then "[#{alert.id}] ")+alert.msg)
    alert.trustedMsg = $sce.trustAsHtml(alert.msg)
    if !alert.id? || !alertsMap[alert.id]
      handleNewAlert(alert)
    else
      handleDupeAlert(alert)

  # expose some functions via scope and event
  $scope.hideAlert = hideAlert # this is used by the alert close button
  $scope.$onRootScope rmapsEventConstants.alert.spawn, handleAlertSpawnEvent
  $scope.$onRootScope rmapsEventConstants.alert.hide, (event, alertId) -> hideAlert(alertId)
  $scope.$onRootScope rmapsEventConstants.alert.dismiss, (event, alertId) -> removeAlert(alertId)
  $scope.$onRootScope rmapsEventConstants.alert.prevent, (event, alertInfo) -> preventAlert(alertInfo)
