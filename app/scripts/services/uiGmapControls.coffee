app = require '../app.coffee'

app.service 'uiGmapControls'.ourNs(), [
  _controls =
    parcels: {}
    streetNumMarkers: {}
    priceMarkers: {}


  _eachChildModel = (cb, toGetFn = undefined) ->
    _.each _controls, (control, k) ->
      control.each (childModel, id) ->
        got = if toGetFn? then toGetFn(childModel) else childModel
        cb(got)

  _eachGObject = (cb) ->
    _eachChildModel cb, (childModel) ->
      childModel.gObject

  _eachSetOptions = (opts) ->
    _eachGObject (gObject) ->
      gObject.setOptions opts

   #specifc we have id of only 3 controls to update
  _eachSpecificChildModel = (id, cb, toGetFn = undefined) ->
    _.each _controls, (control, k) ->
      childModel = control[id]
      got = if toGetFn? then toGetFn(childModel) else childModel
      cb(got)

  _setOptions = (id, opts) ->
    _eachSpecificChildModel id, (childModel) ->
      childModel.gObject.setOptions opts


  #public
  #things to bind to
  parcels: _controls.parcels
  streetNumMarkers: _controls.streetNumMarkers
  priceMarkers: _controls.priceMarkers
  #utilities
  eachChildModel: _eachChildModel
  eachGObject: _eachGObject
  eachSetOptions: _eachSetOptions
  eachSpecificChildModel: _eachSpecificChildModel
  setOptions: _setOptions
]