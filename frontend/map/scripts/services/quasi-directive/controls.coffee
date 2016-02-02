app = require '../../app.coffee'

# Leaflet control directive definitions should have these properties:
#
# name
#    -- Exposed via rmapsControlsService service as {Name}Control
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
,
  name: 'drawtools'
  options:
    position: 'bottomright'
  directive: ($log) ->
    tmp = require('../../../html/includes/map/_drawTools.jade')()
    template: tmp
]

for control in directiveControls
  do (control) ->
    control.dName = control.name[0].toUpperCase() + control.name.slice(1) + 'Control'
    app.directive "rmaps#{control.dName}", ($log, $rootScope) -> control.directive($log.spawn("map:controls:#{control.dName}"))

# Leaflet usage:
#    rmapsControlsService.{Some}Control position: 'botomleft', scope: mapScope
app.service 'rmapsControlsService', ($compile, $rootScope, $log) ->
  $log = $log.spawn('map:rmapsControlsService')
  svc = {}
  for control in directiveControls
    do (control) ->
      control.class = class extends L.Control
        includes: L.Mixin.Events
        options: control.options
        initialize: (options) ->
          $log.spawn("#{control.dName}").debug "init"
          super options
        onAdd: (map) ->
          $log.spawn("#{control.dName}").debug "onAdd"
          wrapper = L.DomUtil.create 'div', 'rmaps-control' + " rmaps-#{control.name}-control"
          wrapper.setAttribute "rmaps-#{control.name}-control", ''
          try
            templateFn = $compile wrapper
            templateFn @options.scope
            L.DomEvent
            .on wrapper, 'click', L.DomEvent.stopPropagation
            .on wrapper, 'mousedown', L.DomEvent.stopPropagation
            .on wrapper, 'dblclick', L.DomEvent.stopPropagation
            .on wrapper, 'mousewheel', L.DomEvent.stopPropagation
            wrapper
          catch e
            $log.error "rmapsControlsService: #{control.name}"
            $log.error e
      try
        svc[control.dName] = (options) -> new control.class(options)
      catch e
        $log.error "rmapsControlsService: #{control.dName}"
        $log.error e

  svc
