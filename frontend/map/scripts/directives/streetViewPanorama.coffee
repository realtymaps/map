app = require '../app.coffee'

app.service "rmapsGoogleEventsHelper", () ->
  _hasEvents = (obj) ->
    angular.isDefined(obj.events) and obj.events? and angular.isObject(obj.events)

  _getEventsObj = (scope, model) ->
    if _hasEvents scope
      return scope
    if _hasEvents model
      return model

  setEvents: (gObject, scope, model, ignores) ->
    eventObj = _getEventsObj scope, model

    if eventObj?
      _.compact _.map eventObj.events, (eventHandler, eventName) ->
        if ignores
          doIgnore = _(ignores).includes(eventName) #ignores to be invoked by internal listeners
        if eventObj.events.hasOwnProperty(eventName) and angular.isFunction(eventObj.events[eventName]) and !doIgnore
          google.maps.event.addListener gObject, eventName, ->
            #$scope.$evalAsync must exist, I have tried null checking, underscore key checking. Nothing works but having a real or fake $evalAsync
            #it would be nice to know why
            unless scope.$evalAsync
              scope.$evalAsync = ->
            scope.$evalAsync(eventHandler.apply(scope, [gObject, eventName, model, arguments]))

  removeEvents: (listeners) ->
    return unless listeners
    for key, l of listeners
      google.maps.event.removeListener(l) if l and listeners.hasOwnProperty(key)
    return

###
@authors:
- Nicholas McCready - https://twitter.com/nmccready
###

###
StreetViewPanorama Directive to care of basic initialization of StreetViewPanorama
###

app.directive 'rmapsStreetViewPanorama', (rmapsGoogleService, $log, rmapsGoogleEventsHelper) ->
  $log = $log.spawn 'rmapsStreetViewPanorama'

  restrict: 'EMA'
  template: '<div class="street-view-panorama"></div>'
  replace: true
  scope:
    focalcoord: '='
    radius: '=?'
    events: '=?'
    options: '=?'
    control: '=?'
    povoptions: '=?'
    imagestatus: '='

  link: (scope, element, attrs) ->
    rmapsGoogleService.getAPI().then (gmaps) ->

      pano = undefined
      sv = undefined
      didCreateOptionsFromDirective = false
      listeners = undefined
      opts = null
      povOpts = null

      clean = ->
        rmapsGoogleEventsHelper.removeEvents listeners

        if pano?
          pano.unbind 'position'
          pano.setVisible false
        if sv?
          sv.setVisible false if sv?.setVisible?
          sv = undefined

      handleSettings = (perspectivePoint, focalPoint) ->
        heading = gmaps.geometry.spherical.computeHeading(perspectivePoint, focalPoint)
        didCreateOptionsFromDirective = true
        #options down
        scope.radius = scope.radius or 50
        povOpts = angular.extend
          heading: heading
          zoom: 1
          pitch: 0
        , scope.povoptions or {}

        opts = opts = angular.extend
          navigationControl: false
          addressControl: false
          linksControl: false
          position: perspectivePoint
          pov: povOpts
          visible: true
        , scope.options or {}
        didCreateOptionsFromDirective = false

      create = ->
        unless scope.focalcoord
          $log.error "#{name}: focalCoord needs to be defined"
          return
        unless scope.radius
          $log.error "#{name}: needs a radius to set the camera view from its focal target."
          return

        clean()

        unless sv?
          sv = new gmaps.StreetViewService()

        if scope.events
          listeners = rmapsGoogleEventsHelper.setEvents sv, scope, scope

        # originally part of uiGmapgoogle-maps.directives.api.utils
        getCoords = (value) ->
          return unless value
          if value instanceof google.maps.LatLng
            return value
          else if Array.isArray(value) and value.length is 2
            new google.maps.LatLng(value[1], value[0])
          else if angular.isDefined(value.type) and value.type is 'Point'
            new google.maps.LatLng(value.coordinates[1], value.coordinates[0])
          else
            new google.maps.LatLng(value.latitude, value.longitude)

        focalPoint = getCoords scope.focalcoord

        sv.getPanoramaByLocation focalPoint, scope.radius, (streetViewPanoramaData, status) ->
          #get status via scope or callback
          scope.imagestatus = status if scope.imagestatus?
          if scope.events?.image_status_changed?
            scope.events.image_status_changed(sv, 'image_status_changed', scope, status)
          if status is "OK"
            perspectivePoint = streetViewPanoramaData.location.latLng
            #derrived
            handleSettings(perspectivePoint, focalPoint)
            ele = element[0]
            pano = new gmaps.StreetViewPanorama(ele, opts)


      if scope.control?
        scope.control.getOptions = ->
          opts
        scope.control.getPovOptions = ->
          povOpts
        scope.control.getGObject = ->
          sv
        scope.control.getGPano = ->
          pano

      scope.$watch 'options', (newValue, oldValue) ->
        #options are limited so we do not have to worry about them conflicting with positon
        return if newValue == oldValue or newValue == opts  or didCreateOptionsFromDirective
        create()

      firstTime = true
      scope.$watch 'focalcoord', (newValue, oldValue) ->
        return if newValue ==  oldValue and not firstTime
        return unless newValue?
        firstTime = false
        create()

      scope.$on '$destroy', ->
        clean()