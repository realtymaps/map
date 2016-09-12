_delay = 0 #ms

###globals L###
#TODO: This really should be a directive in angular-leaflet eventually (nmccready)
app = require '../../app.coffee'
_defaultOptions =
  closeButton: false
  offset: new L.Point(0, -5)
  autoPan: false
  maxWidth: 9999

app.service 'rmapsPopupGetOffset', () ->

  ({map, model, offsets}) ->
    # get center and point container coords
    return if !model?.coordinates?.length
    center = map.latLngToContainerPoint map.getCenter()
    point = map.latLngToContainerPoint new L.LatLng model.coordinates[1], model.coordinates[0]

    # ascertain near which container corner the marker is in
    quadrant = ''
    quadrant += (if (point.y > center.y) then 'b' else 't')
    quadrant += (if (point.x < center.x) then 'l' else 'r')

    # create offset point per quadrant
    return switch
      when quadrant is 'tr' then new L.Point offsets.right, offsets.top
      when quadrant is 'tl' then new L.Point offsets.left, offsets.top
      when quadrant is 'br' then new L.Point offsets.right, offsets.bottom
      else new L.Point offsets.left, offsets.bottom


app.factory 'rmapsPopupFactory', (
  $log,
  $rootScope,
  $compile,
  rmapsPopupConstants,
  rmapsPopupGetOffset
) ->

  $log = $log.spawn("map:rmapsPopupFactory")

  class
    constructor: ({@map, model, opts = _defaultOptions, needToCompile = true, templateVars, @canClose = false, @index, @closedCb}) ->
      @isLoading = true
      @popup = rmapsPopupConstants[model.markerType]
      @popup ?= rmapsPopupConstants.default
      template = @popup.templateFn(templateVars)

      return if model?.markerType == 'cluster'
      content = null

      coords = model.coordinates or model.geometry_center?.coordinates

      # template for the popup box
      if needToCompile
        @scope = $rootScope.$new()
        @scope.model = model
        @popupIsHovered = false

        compiled = $compile(template)(@scope)
        content = compiled[0]
      else
        content = template

      # set the offset
      opts.offset = rmapsPopupGetOffset {@map, model, offsets: @popup.offsets}

      # generate and apply popup object
      if @lObj
        $log.debug "L.Util.setOptions (#{model.markerType}):", opts
        L.Util.setOptions @lObj, opts
      else
        $log.debug "new L.popup (#{model.markerType}):", opts
        @lObj = new L.popup opts

      @isLoading = false

      @lObj
      .setLatLng(lat: coords[1], lng: coords[0])
      .setContent content
      .openOn @map

      # If popup appears under the mouse cursor, it may 'steal' the events that would have fired on the marker
      # This is an attempt to make sure the popup goes away once the cursor is moved away
      @lObj._container?.addEventListener 'mouseleave', (e) =>
        @popupIsHovered = false
        return if !@canClose

      @lObj._container?.addEventListener 'mouseover', (e) =>
        @popupIsHovered = true

      @canClose = true

    close: () ->
      return if !@canClose
      if !@popupIsHovered
        $log.debug 'closing popup'
        @map?.closePopup()
        @scope?.$destroy()
        @scope = null
        return

app.service 'rmapsPopupLoaderService',(
  $log,
  rmapsPopupFactory,
  $timeout
) ->
  _popup = null
  _timeoutPromiseQueue = []
  $log = $log.spawn("map:rmapsPopupLoaderService")

  load: (opts) ->
    $log.debug "popup type #{opts.model.markerType} loading in #{_delay}ms..."

    if _timeoutPromiseQueue.length
      promise = _timeoutPromiseQueue.shift()
      $timeout.cancel(promise) if promise?

    _timeoutPromiseQueue.push $timeout () ->
      _popup = new rmapsPopupFactory opts
    , _delay

  close: () ->
    popupExists = _popup?
    if popupExists
      $log.debug "popup closing"
      _popup?.close()
      _popup = null
    return popupExists
