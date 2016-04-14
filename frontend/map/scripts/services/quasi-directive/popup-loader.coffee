#TODO: This really should be a directive in angular-leaflet eventually (nmccready)
app = require '../../app.coffee'
_defaultOptions = {closeButton: false, offset: new L.Point(0, -5), autoPan: false}

app.service 'rmapsPopupLoaderService', ($log, $rootScope, $compile, rmapsPopupConstants, rmapsRenderingService, $timeout) ->
  _map = null #TODO this ref shouldn't be global if so this should become a factory
  _templateScope = null
  _renderPromises =
    loadPromise: false
  _lObj =  null
  _handleMouseMove = null
  _delay = 100 #ms
  _timeoutPromise = null

  $log = $log.spawn("map:popupLoader")

  _close =  ->
    return unless _map
    $log.debug 'closing popup'
    # _map.closePopup()
    _templateScope?.$destroy()
    _templateScope = null
    $timeout.cancel _timeoutPromise if _timeoutPromise

  _getOffset = (map, model, offsets) ->
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

  _popup = ({map, model, opts, needToCompile, popupType, templateVars}) ->
    popup = rmapsPopupConstants[popupType]
    popup ?= rmapsPopupConstants.default
    opts ?= _defaultOptions
    template = popup.templateFn(templateVars)
    needToCompile ?= true
    _map = map
    return if model?.markerType == 'cluster'
    content = null

    coords = model.coordinates or model.geom_point_json?.coordinates

    # template for the popup box
    if needToCompile
      _templateScope = $rootScope.$new() unless _templateScope?
      _templateScope.model = model
      compiled = $compile(template)(_templateScope)
      content = compiled[0]
    else
      content = template

    # set the offset
    opts.offset = _getOffset map, model, popup.offsets

    # generate and apply popup object
    if _lObj
      $log.debug "L.Util.setOptions (#{popupType}): " + opts
      L.Util.setOptions _lObj, opts
    else
      $log.debug "new L.popup (#{popupType}): " + opts
      _lObj = new L.popup opts

    _lObj.setLatLng
      lat: coords[1]
      lng: coords[0]
    .openOn map
    _lObj.setContent content

    # If popup appears under the mouse cursor, it may 'steal' the events that would have fired on the marker
    # This is an attempt to make sure the popup goes away once the cursor is moved away
    _lObj._container?.addEventListener 'mouseleave', (e) ->
      map.closePopup()

    _lObj

  load: (opts) ->
    $log.debug "popup loading in #{_delay}ms..."
    _popupArgs = arguments

    $timeout.cancel _timeoutPromise if _timeoutPromise

    _timeoutPromise = $timeout () ->
      _popup opts
    , _delay

  close: _close

  getCurrent: -> _lObj
