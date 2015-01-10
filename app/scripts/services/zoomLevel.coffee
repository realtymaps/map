app = require '../app.coffee'

keysToValue = require '../../../common/utils/util.keysToValues.coffee'


app.service 'ZoomLevel'.ourNs(), ['MainOptions'.ourNs(), (options) ->
  _zoomThresh = options.map.options.zoomThresh
  _enum = keysToValue
    addressParcel: 1
    parcel: 1
    price: 1


  _enumFromLevel = (currentLevel) ->
    if currentLevel < _zoomThresh.price
      return _enum.price
    if currentLevel >= _zoomThresh.price and currentLevel < _zoomThresh.addressParcel
      return _enum.parcel
    if currentLevel >= _zoomThresh.addressParcel
      return _enum.addressParcel

  _enumFromMap = (gMap) ->
    _enumFromLevel gMap.getZoom()

  _is = (gMapOrInt, stateObj, stateToCheck) ->
    stateObj.zoomLevel = if _.isNumber(gMapOrInt) then _enumFromLevel(gMapOrInt) else _enumFromMap gMapOrInt
    stateToCheck == stateObj.zoomLevel
  Enum: _enum
  enumFromLevel: _enumFromLevel
  enumFromMap: _enumFromMap

  #boolean checks with side effects to save the enum state to some object
  isPrice: (gMapOrInt, stateObj = {}) ->
    _is(gMapOrInt, stateObj, _enum.price)
  isParcel: (gMapOrInt, stateObj = {}) ->
    _is(gMapOrInt, stateObj, _enum.parcel)
  isAddressParcel: (gMapOrInt, stateObj = {}) ->
    _is(gMapOrInt, stateObj, _enum.addressParcel)
]
