_ = require 'lodash'
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
utilsGeoJson =  require '../../../../common/utils/util.geomToGeoJson.coffee'
analyzeValue = require  '../../../../common/utils/util.analyzeValue.coffee'

app.service 'rmapsPropertiesService', ($rootScope, $http, $q, rmapsPropertyFactory,
  rmapsEventConstants, rmapsPromiseThrottlerFactory, $log) ->

  $log = $log.spawn("map:rmapsPropertiesService")

  #
  # Service Instance
  #
  service = {}


  #
  # API throttling
  #

  _detailThrottler = new rmapsPromiseThrottlerFactory('detailThrottler')
  _filterThrottler = new rmapsPromiseThrottlerFactory('filterThrottler')
  _filterThrottlerCluster = new rmapsPromiseThrottlerFactory('filterThrottlerCluster')
  _parcelThrottler = new rmapsPromiseThrottlerFactory('parcelThrottler')
  _addressThrottler = new rmapsPromiseThrottlerFactory('addressThrottler')

  #
  # Service Implementation
  #

  _getState = (mapState = {}, filters) ->
    # $log.debug "mapState: #{JSON.stringify mapState}"
    # $log.debug "filters: #{JSON.stringify filters}"
    result = _.extend {}, mapState

    # Only include the filters if a set of values is explicitly being passed, otherwise ignore so that the
    # state object will not have the filters key at all
    if filters
      result.filters = filters

    return result

  # this convention for a combined service call helps elsewhere because we know how to get the path used
  # by this call, which means we can do things with alerts related to it
  _getPropertyData = (pathId, hash, mapState, returnType, filters, cache = true) ->
    return null if !hash?

    bodyExtensions = {}

    if returnType? and !_.isString(returnType)
      $log.error "returnType is not a string. returnType: #{returnType}"

    if $rootScope.propertiesInShapes and returnType  #is drawnShapes filterSummary
      pathId = 'drawnShapes'
      bodyExtensions.isArea = true

    route = backendRoutes.properties[pathId]

    $log.debug () -> "filters: #{JSON.stringify filters}"
    $log.debug mapState
    $log.debug(route)

    $http.post(route, _.extend({}, bodyExtensions,
      bounds: hash
      returnType: returnType
      state: _getState(mapState, filters))
    , cache: cache)

  _getFilterSummary = (hash, mapState, returnType, filters, cache = true, throttler = _filterThrottler) ->
    throttler.invokePromise(
      _getPropertyData('filterSummary', hash, mapState, returnType, filters, cache)
      , http: {route: backendRoutes.properties.filterSummary })

  _pinForMap = (model, save = true) ->
    if save
      _.merge model, savedDetails: isPinned: true
    else
      delete model.savedDetails?.isPinned

  _pinProperty = (model, save = true) ->
    if !model?.rm_property_id?
      return $q.resolve()
    {rm_property_id} = model

    promise = if save
      $http.post backendRoutes.properties.pin, {rm_property_id}
      .then () ->
        service.pins[rm_property_id] = _pinForMap model
    else
      $http.post backendRoutes.properties.unPin, {rm_property_id}
      .then () ->
        _pinForMap model, false
        delete service.pins[rm_property_id]

    promise
    .catch (error) -> #our state is messed up force refresh
      $log.error "Pin/unPin failed with error: #{analyzeValue(error)}. Forcing refresh!"
      _loadProperties(model)

  _favoriteForMap = (model, save = true) ->
    if save
      _.merge model, savedDetails: isFavorite: true
    else
      delete model.savedDetails?.isFavorite

  _favoriteProperty = (model) ->
    if !model?.rm_property_id
      return $q.resolve()
    {rm_property_id} = model

    promise = if !service.favorites[rm_property_id]?
      $http.post backendRoutes.properties.favorite, {rm_property_id}
      .then () ->
        service.favorites[rm_property_id] = _favoriteForMap model
    else
      $http.post backendRoutes.properties.unFavorite, {rm_property_id}
      .then () ->
        _favoriteForMap model, false
        delete service.favorites[rm_property_id]

    promise
    .catch (error) -> #our state is messed up force refresh
      $log.error "Favorite/unFavorite failed with error: #{analyzeValue(error)}. Forcing refresh!"
      _loadProperties(model)

  _setFlags = (model) ->
    return if !model or !model.rm_property_id
    rm_property_id = model.rm_property_id

    model.savedDetails ?= new rmapsPropertyFactory(rm_property_id)
    model.savedDetails.isPinned = !!service.pins[rm_property_id]
    model.savedDetails.isFavorite = !!service.favorites[rm_property_id]

  _loadProperties = (model) ->
    $log.debug 'Loading property', model.rm_property_id
    service.getProperties [model.rm_property_id], 'filter'
    .then ({data}) ->
      for detail in data
        if model = service.pins[detail.rm_property_id]
          _.extend model, detail
          _pinForMap model
        if model = service.favorites?[detail.rm_property_id]
          _.extend model, detail
          _favoriteForMap model

      $log.debug 'Loaded property', model.rm_property_id

  _processPropertyPins = (models) ->
    $rootScope.$emit rmapsEventConstants.update.properties.pin,
      property: models[0],
      properties: service.pins

  ###
   Service API Definition

   will receive results from backend, which will be organzed either as
   standard results or cluster results, determined in backend by #of results returned
  ###
  service.getFilterResults = (hash, mapState, filters, cache = true) ->
    _getFilterSummary(hash, mapState, 'clusterOrDefault', filters, cache)

  service.getFilterSummary = (hash, mapState, filters, cache = true) ->
    _getFilterSummary(hash, mapState, undefined, filters, cache)

  service.getFilterSummaryAsCluster = (hash, mapState, filters, cache = true) ->
    _getFilterSummary(hash, mapState, 'cluster', filters, cache, _filterThrottlerCluster)

  service.getFilterSummaryAsGeoJsonPolys = (hash, mapState, filters, data) ->
    #forcing this to always use a cached val since getFilterResults will always be run prior

    # doClone should be false eventually, but we need to fix ui-leaflet to allow
    # for geojson to have different property atribute names, so markers and geojson don't collide
    doClone = true

    if !data?
      promise = service.getFilterResults(hash, mapState, filters, true)
    else
      doClone = true
      promise = $q.resolve data

    promise.then (data) ->
      utilsGeoJson.toGeoFeatureCollection({rows: data, doClone})

  service.getParcelBase = (hash, mapState, cache = true) ->
    _parcelThrottler.invokePromise _getPropertyData(
      'parcelBase', hash, mapState, undefined, undefined, cache)
    , http: {route: backendRoutes.properties.parcelBase }

  service.getAddresses = (hash, mapState, cache = true) ->
    _addressThrottler.invokePromise _getPropertyData(
      'addresses', hash, mapState, undefined, undefined, cache)
    , http: {route: backendRoutes.properties.parcelBase }

  service.getPropertyDetail = (mapState, queryObj, columns, cache = true) ->
    promise =
      $http.post(backendRoutes.properties.detail,
      _.extend({}, queryObj,{ state: _getState(mapState), columns: columns }), cache: cache)

    _detailThrottler.invokePromise(promise, http: route: backendRoutes.properties.detail).then (property) ->
      _setFlags property
      property

  service.updateMapState = (mapState) ->
    $http.post backendRoutes.properties.mapState, state: _getState(mapState)

  service.getProperties = (ids, columns) ->
    $http.post backendRoutes.properties.details, rm_property_id: ids, columns: columns

  service.getSaves = () ->
    $http.getData backendRoutes.properties.saves, cache: false

  service.pinUnpinProperty = (models) ->
    if !_.isArray models
      models = [ models ]

    for m in models
      _.merge  m, service.pins[m.rm_property_id] || service.favorites[m.rm_property_id]

    $q.all _.map models, (model) ->
      _pinProperty model, !model.savedDetails?.isPinned

    .then () ->
      _processPropertyPins models

  service.favoriteProperty = (model) ->
    _favoriteProperty(model)
    .then () ->
      $rootScope.$emit rmapsEventConstants.update.properties.favorite,
        property: model,
        properties: service.favorites

  service.isPinnedProperty = (propertyId) ->
    !!service.pins?[propertyId]

  service.isFavoriteProperty = (propertyId) ->
    !!service.favorites?[propertyId]

  # Map calls this to update property objects
  service.updateProperty = (model) ->
    if !model?.rm_property_id?
      return
    if prop = service.pins?[model.rm_property_id]
      service.pins[model.rm_property_id] = model
      if !model.savedDetails
        model.savedDetails = prop.savedDetails

    if prop = service.favorites?[model?.rm_property_id]
      service.favorites[model.rm_property_id] = model
      if !model.savedDetails
        model.savedDetails = prop.savedDetails
      else
        _.extend model.savedDetails, prop.savedDetails

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, currentProfile) ->
    service.pins = currentProfile.pins
    service.favorites = currentProfile.favorites
    propertyIds = _.keys(service.pins).concat _.keys(service.favorites)
    if propertyIds.length
      $log.debug 'Loading', propertyIds.length, 'properties from new profile'
      service.getProperties propertyIds, 'filter'
      .then ({data}) ->
        for detail in data
          if model = service.pins[detail.rm_property_id]
            _.extend model, detail
            _pinForMap model
          if model = service.favorites[detail.rm_property_id]
            _.extend model, detail
            _favoriteForMap model

        $log.debug 'Loaded', propertyIds.length, 'properties from new profile'

  return service
