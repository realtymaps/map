directiveName = 'lfDraw'
angular.module('ui-leaflet')
.config ($provide, nemDebugProvider) ->
  debug = nemDebugProvider.debug
  debug.enable("config:*")
  log = debug("config:#{directiveName}")

  $provide.decorator 'leafletDirective', ($delegate) ->
    directive = $delegate[0]
    directive.scope[directiveName] = '=?' #the way it should be
    #the above should derrive $$isolateBindings this without the below hack
    #workaround from http://plnkr.co/edit/CRxhX6?p=preview
    directive.$$isolateBindings[directiveName] =
      attrName: directiveName
      mode: '='
      optional: true

    # log directive.scope
    log $delegate
    $delegate

#Note styling this Leaflet.Draw.DrawTool sucks
.directive directiveName, (leafletLogger, leafletData, leafletHelpers, leafletIterators, $timeout, $q) ->
  $log = leafletLogger
  isDefined = leafletHelpers.isDefined
  errorHeader = leafletHelpers.errorHeader

  restrict: 'A'
  scope: false
  replace: false
  require: ['leaflet']
  controller: ($scope) ->
    @_deferredDrawTool = $q.defer()
    @getDrawTool = ->
      @_deferredDrawTool.promise
    @getScope = ->
      $scope

  link: (scope, element, attrs, controller) ->
    mapController = controller[0]
    leafletScope = mapController.getLeafletScope()
    _featureGroup = undefined
    _optionsEditedInDirective = false
    _deferred = undefined

    leafletScope.$watchCollection directiveName, ->
      if !_deferred || _deferred.resolvedDefer
        _deferred = $q.defer()#temp hack until directiveControls is more flexible
      return if _optionsEditedInDirective
      #TODO Watch options and recreate control
      options = leafletScope[directiveName] or {}

      if options.control?
        options.control.promised _deferred.promise

      mapController.getMap().then (map) ->
        if _featureGroup
          map.removeLayer _featureGroup

        if !isDefined L.Control.Draw
          $log.error "#{errorHeader} Leaflet.Draw is not loaded as a plugin."
          return

        if !isDefined(options.edit) or !isDefined(options.edit.featureGroup)
          _optionsEditedInDirective = true
          angular.extend options,
            edit:
              featureGroup: new L.FeatureGroup()

          $timeout -> _optionsEditedInDirective = false #skip extra digest due to above mod

        _featureGroup = options.edit.featureGroup
        map.addLayer(_featureGroup)
        drawControl = new L.Control.Draw options

        map.addControl drawControl
        _deferred.resolvedDefer = true
        _deferred.resolve
          control: drawControl
          map:map


        #TODO Add in event handling via extending leafletEvents for leafletDrawEvents


###
Possibly Write Directives that Simply Call the Draw Objects to instantiate drawing.
That way the templates can be whatever. Directive or html via ngDirectives
###
