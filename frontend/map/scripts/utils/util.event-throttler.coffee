###globals _###
module.exports = ($log, options) ->
  last =
    time: new Date() # last time we let an event pass.
    x: -100 # last x position af the event that passed.
    y: -100 # last y position af the event that passed.

  _doThrottle = (event, distance, time) ->
    if event.type == 'mousewheel'
      return time < options.throttle.eventPeriods.mousewheel
    distance * time < options.throttle.space * options.throttle.eventPeriods.mousemove

  _debouncedDebug = _.debounce (msg) ->
    $log.debug msg
  , 1000

  @throttle_events = (event) ->
    now = new Date()
    distance = Math.sqrt(Math.pow(event.clientX - last.x, 2) + Math.pow(event.clientY - last.y, 2))
    time = now.getTime() - last.time.getTime()
    if _doThrottle(event, distance, time)  #event arrived too soon or mouse moved too little or both
      _debouncedDebug 'event stopped'
      if event.stopPropagation # W3C/addEventListener()
        event.stopPropagation()
      else # Older IE.
        event.cancelBubble = true
    else
      $log.debug 'event allowed: ' + now.getTime() if event.type == 'mousewheel'
      last.time = now
      last.x = event.clientX
      last.y = event.clientY
    return
  @
