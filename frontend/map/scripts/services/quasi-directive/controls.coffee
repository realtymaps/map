app = require '../../app.coffee'

# Leaflet control directive definitions should have these properties:
#
# name
#    -- Exposed via rmapsControls service as {Name}Control
# options
#    -- standard Leaflet control options e.g. position, plus scope
# directive
#    -- angular directive definition
#
directiveControls = [
  name: 'navigation'
  options:
    position: 'topleft'
  directive:
    template: require('../../../html/includes/navigation.jade')()
,
  name: 'properties'
  options:
    position: 'topright'
  directive:
    template: require('../../../html/includes/properties.jade')()
,
  name: 'layer'
  options:
    position: 'bottomleft'
  directive:
    template: require('../../../html/includes/layers.jade')()
    compile: (tElement, tAttrs, transclude) ->
      console.debug 'LayerControl compile'
      (scope, iElement, iAttrs, controller, transcludeFn) ->
        console.debug 'LayerControl link'
,
  name: 'location'
  options:
    position: 'bottomleft'
  directive:
    template: require('../../../html/includes/location.jade')()
]

for control in directiveControls
  do (control) ->
    control.dName = control.name[0].toUpperCase() + control.name.slice(1) + 'Control'
    app.directive "rmaps#{control.dName}", -> control.directive

# Leaflet usage:
#    rmapsControls.{Some}Control position: 'botomleft', scope: mapScope
app.service 'rmapsControls', ($compile) ->
  svc = {}
  for control in directiveControls
    do (control) ->
      control.class = class extends L.Control
        includes: L.Mixin.Events
        options: control.options
        initialize: (options) ->
          console.debug "#{control.dName} init"
          super options
        onAdd: (map) ->
          console.debug "#{control.dName} onAdd"
          wrapper = L.DomUtil.create 'div', 'rmaps-control'
          wrapper.setAttribute "rmaps-#{control.name}-control", ''
          templateFn = $compile wrapper
          templateFn @options.scope
          L.DomEvent
          .on wrapper, 'click', L.DomEvent.stopPropagation
          .on wrapper, 'mousedown', L.DomEvent.stopPropagation
          .on wrapper, 'dblclick', L.DomEvent.stopPropagation
          wrapper

      svc[control.dName] = (options) -> new control.class(options)

  svc
