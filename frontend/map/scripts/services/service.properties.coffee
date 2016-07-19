###globals _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
utilsGeoJson =  require '../../../../common/utils/util.geomToGeoJson.coffee'
analyzeValue = require  '../../../../common/utils/util.analyzeValue.coffee'

app.service 'rmapsPropertiesService', ($rootScope, $http, $q, rmapsPropertyFactory, rmapsPrincipalService,
  rmapsEventConstants, rmapsPromiseThrottlerFactory, $log) ->

  $log = $log.spawn("map:rmapsPropertiesService")

  #
  # Service Instance
  #
  service = {}

  #
  # Pins and Favorites cache
  #

  #HASH to properties by rm_property_id
  #we may want to save details beyond just saving there fore it will be a hash pointing to an object
  service.pins = {}
  service.favorites = {}

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

  # Reset the properties hash when switching profiles
  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, profile) ->
    $log.debug 'rmapsEventConstants.principal.profile.updated: re-loading saved properties'
    _loadProperties(true)
    .then () ->
      $rootScope.$emit rmapsEventConstants.update.properties.pin, properties: service.pins
      $rootScope.$emit rmapsEventConstants.update.properties.favorite, properties: service.favorites

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
      _loadProperties(true)

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
      _loadProperties(true)

  _setFlags = (model) ->
    return if !model or !model.rm_property_id
    rm_property_id = model.rm_property_id

    model.savedDetails ?= new rmapsPropertyFactory(rm_property_id)
    model.savedDetails.isPinned = !!service.pins[rm_property_id]
    model.savedDetails.isFavorite = !!service.favorites[rm_property_id]

  _loadProperties = (force) ->
    service.getSaves()
    .then (response) ->
      $log.debug "saves: #{JSON.stringify response}"
      if (!Object.keys(service.pins).length && !Object.keys(service.favorites).length) || force
        $log.debug 'refreshing saves'
        #fresh initial load
        service.pins = response.pins
        service.favorites = response.favorites
        propertyIds = _.keys(service.pins).concat _.keys(service.favorites)

        service.getProperties propertyIds, 'filter'
        .then ({data}) ->

          for detail in data
            if model = service.pins[detail.rm_property_id]
              _.extend model, detail
              _pinForMap model
            if model = service.favorites?[detail.rm_property_id]
              _.extend model, detail
              _favoriteForMap model

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
    promise = if !data?
      service.getFilterResults(hash, mapState, filters, true)
    else
      $q.resolve data

    promise.then (data) ->
      utilsGeoJson.toGeoFeatureCollection(data)

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
    !!service.pins[propertyId]

  service.isFavoriteProperty = (propertyId) ->
    !!service.favorites[propertyId]

  # Map calls this to update property objects
  service.updateProperty = (model) ->
    if prop = service.pins[model?.rm_property_id]
      service.pins[model.rm_property_id] = model
      if !model.savedDetails
        model.savedDetails = prop.savedDetails

    if prop = service.favorites[model?.rm_property_id]
      service.favorites[model.rm_property_id] = model
      if !model.savedDetails
        model.savedDetails = prop.savedDetails
      else
        _.extend model.savedDetails, prop.savedDetails

  return service
