#TODO: This really should be a directive in angular-leaflet eventually (nmccready)
app = require '../../app.coffee'
_defaultOptions = {closeButton: false, offset: new L.Point(0, -5), autoPan: false}
_defaultTemplate = do require '../../../html/includes/map/_smallDetailsPopup.jade'

app.service 'rmapsPopupLoader', ($rootScope, $compile, rmapspopupVariables, rmapsRendering, $timeout) ->
  _map = null #TODO this ref shouldn't be global if so this should become a factory
  _templateScope = null
  _renderPromises =
    loadPromise: false
  _lObj =  null
  _handleMouseMove = null

  _close =  ->
    return unless _map
    _map.closePopup()

  _getOffset = (map, model, offsets = rmapspopupVariables.offsets) ->
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


  load: ($scope, map, model, lTriggerObject, opts = _defaultOptions, template = _defaultTemplate, needToCompile = true) ->
    $timeout -> #hack to deal with close happening at the same time (already tried boolean gates)
      _map = map
      return if model?.markerType == 'cluster'
      content = null

      coords = model.coordinates or model.geom_point_json?.coordinates

      # template for the popup box
      if needToCompile
        _templateScope = $scope.$new() unless _templateScope?
        _templateScope.model = model
        compiled = $compile(template)(_templateScope)
        content = compiled[0]
      else
        content = template

      # set the offset
      opts.offset = _getOffset map, model

      # generate and apply popup object
      if _lObj
        L.Util.setOptions _lObj, opts
      else
        _lObj = new L.popup opts

      _lObj.setLatLng
        lat: coords[1]
        lng: coords[0]
      .openOn map
      _lObj.setContent content
      _lObj
    , 100
  close: _close

  getCurrent: -> _lObj
