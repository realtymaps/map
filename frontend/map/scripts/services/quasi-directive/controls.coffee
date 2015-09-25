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
  directive: ($log) ->
    template: require('../../../html/includes/map/_navigation.jade')()
,
  name: 'properties'
  options:
    position: 'topright'
  directive: ($log) ->
    template: require('../../../html/includes/map/_propertiesButton.jade')()
,
  name: 'layer'
  options:
    position: 'bottomleft'
  directive: ($log) ->
    template: require('../../../html/includes/map/_layers.jade')()
    compile: (tElement, tAttrs, transclude) ->
      $log.debug 'LayerControl compile'
      (scope, iElement, iAttrs, controller, transcludeFn) ->
        $log.debug 'LayerControl link'
,
  name: 'location'
  options:
    position: 'bottomleft'
  directive: ($log) ->
    template: require('../../../html/includes/map/_location.jade')()
]

for control in directiveControls
  do (control) ->
    control.dName = control.name[0].toUpperCase() + control.name.slice(1) + 'Control'
    app.directive "rmaps#{control.dName}", (rmapsMapControlsLogger, $rootScope) -> control.directive(rmapsMapControlsLogger) unless $rootScope.silenceRmapsControls

# Leaflet usage:
#    rmapsControls.{Some}Control position: 'botomleft', scope: mapScope
app.service 'rmapsControls', ($compile, rmapsMapControlsLogger, $rootScope) ->
  svc = {}
  for control in directiveControls
    do (control) ->
      control.class = class extends L.Control
        includes: L.Mixin.Events
        options: control.options
        initialize: (options) ->
          rmapsMapControlsLogger.debug "#{control.dName} init" unless $rootScope.silenceRmapsControls
          super options
        onAdd: (map) ->
          rmapsMapControlsLogger.debug "#{control.dName} onAdd" unless $rootScope.silenceRmapsControls
          wrapper = L.DomUtil.create 'div', 'rmaps-control' + " rmaps-#{control.name}-control"
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
