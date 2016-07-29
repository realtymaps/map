###globals _###
app = require '../app.coffee'

keysToValue = require '../../../../common/utils/util.keysToValues.coffee'

app.service 'rmapsZoomLevelService', (rmapsMainOptions, $log) ->
  _zoomThresh = rmapsMainOptions.map.options.zoomThresh
  Enum = keysToValue
    addressParcel: 1
    parcel: 1
    price: 1
  _prevZoom = null
  _currZoom = null

  trackZoom = (scope) ->
    # only if initial state or zoom has changed, set new prev and curr
    if _currZoom != getZoom(scope)
      _prevZoom = _currZoom
      _currZoom = getZoom(scope)

  # determine if we zoomed out from "price" level zoom (to figure out if we need to turn markers back on)
  isFromParcelZoom = () ->
    return _currZoom < _prevZoom and _currZoom <= _zoomThresh.price and _prevZoom > _zoomThresh.price

  getZoom = (scope) ->
    scope.map?.center?.zoom

  enumFromLevel = (currentLevel) ->
    $log.error 'currentLevel undefined from enumFromLevel' unless currentLevel
    if currentLevel <= _zoomThresh.price
      return Enum.price
    if currentLevel >  _zoomThresh.price and currentLevel < _zoomThresh.addressParcel
      return Enum.parcel
    if currentLevel >= _zoomThresh.addressParcel
      return Enum.addressParcel
    return Enum.addressParcel

  enumFromMap = (scope) ->
    enumFromLevel scope.map?.center?.zoom

  _is = (gMapOrInt, stateObj = {}, stateToCheck) ->
    stateObj.zoomLevel = if _.isNumber(gMapOrInt) or _.isString(gMapOrInt) then enumFromLevel(gMapOrInt) else enumFromMap gMapOrInt
    stateToCheck == stateObj.zoomLevel

  dblClickZoom = do ->
    _enableDisable = (scope, bool) ->
      scope.options = _.extend {}, scope.options, disableDoubleClickZoom: bool
    enable: (scope) ->
      _enableDisable(scope, false) if scope.options.disableDoubleClickZoom
    disable: (scope) ->
      _enableDisable(scope, true) unless scope.options.disableDoubleClickZoom
  #public
  {
    doCluster: (scope) ->
      getZoom(scope) <= _zoomThresh.roundOne
    #boolean checks with side effects to save the enum state to some object
    isPrice: (gMapOrInt, stateObj) ->
      _is(gMapOrInt, stateObj, Enum.price)
    isParcel: (gMapOrInt, stateObj) ->
      _is(gMapOrInt, stateObj, Enum.parcel)
    isAddressParcel: (gMapOrInt, stateObj) ->
      _is(gMapOrInt, stateObj, Enum.addressParcel)

    isBeyondCartoDb: (currentLevel) ->
      currentLevel > _zoomThresh.addressParcel

    Enum
    enumFromLevel
    enumFromMap
    getZoom
    trackZoom
    isFromParcelZoom
    dblClickZoom
  }
