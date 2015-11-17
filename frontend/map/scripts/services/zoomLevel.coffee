app = require '../app.coffee'

keysToValue = require '../../../../common/utils/util.keysToValues.coffee'

app.service 'rmapsZoomLevel', (rmapsMainOptions, $log) ->
  _zoomThresh = rmapsMainOptions.map.options.zoomThresh
  _enum = keysToValue
    addressParcel: 1
    parcel: 1
    price: 1

  _getZoom = (scope) ->
    scope.map?.center?.zoom

  _enumFromLevel = (currentLevel) ->
    $log.error 'currentLevel undefined from _enumFromLevel' unless currentLevel
    if currentLevel <= _zoomThresh.price
      return _enum.price
    if currentLevel >  _zoomThresh.price and currentLevel < _zoomThresh.addressParcel
      return _enum.parcel
    if currentLevel >= _zoomThresh.addressParcel
      return _enum.addressParcel
    return _enum.addressParcel

  _enumFromMap = (scope) ->
    _enumFromLevel scope.map?.center?.zoom

  _is = (gMapOrInt, stateObj, stateToCheck, isGreater) ->
    stateObj.zoomLevel = if _.isNumber(gMapOrInt) or _.isString(gMapOrInt) then _enumFromLevel(gMapOrInt) else _enumFromMap gMapOrInt
    stateToCheck == stateObj.zoomLevel

  _dblClickZoom = do ->
    _enableDisable = (scope, bool) ->
      scope.options = _.extend {}, scope.options, disableDoubleClickZoom: bool
    enable: (scope) ->
      _enableDisable(scope, false) if scope.options.disableDoubleClickZoom
    disable: (scope) ->
      _enableDisable(scope, true) unless scope.options.disableDoubleClickZoom
  #public
  Enum: _enum
  enumFromLevel: _enumFromLevel
  enumFromMap: _enumFromMap


  getZoom: _getZoom

  doCluster: (scope) ->
    _getZoom(scope) <= _zoomThresh.roundOne
  #boolean checks with side effects to save the enum state to some object
  isPrice: (gMapOrInt, stateObj = {}) ->
    _is(gMapOrInt, stateObj, _enum.price)
  isParcel: (gMapOrInt, stateObj = {}) ->
    _is(gMapOrInt, stateObj, _enum.parcel)
  isAddressParcel: (gMapOrInt, stateObj = {}) ->
    _is(gMapOrInt, stateObj, _enum.addressParcel)

  isBeyondCartoDb: (currentLevel) ->
    currentLevel > _zoomThresh.addressParcel

  dblClickZoom: _dblClickZoom
