###globals _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
utilsGeoJson =  require '../../../../common/utils/util.geomToGeoJson.coffee'

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
  _filterThrottlerGeoJson = new rmapsPromiseThrottlerFactory('filterThrottlerGeoJson')
  _filterThrottlerCluster = new rmapsPromiseThrottlerFactory('filterThrottlerCluster')
  _parcelThrottler = new rmapsPromiseThrottlerFactory('parcelThrottler')
  _saveThrottler = new rmapsPromiseThrottlerFactory('saveThrottler')
  _addressThrottler = new rmapsPromiseThrottlerFactory('addressThrottler')

  #
  # Service Implementation
  #

  # Reset the properties hash when switching profiles
  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, profile) ->
    propertyIds = _.union _.keys(profile.properties_selected), _.keys(profile.favorites)

    service.getProperties propertyIds, 'filter'
    .then ({data}) ->
      service.pins = {}
      service.favorites = {}

      for detail in data
        if model = profile.properties_selected[detail.rm_property_id]
          _.extend model, detail
          _saveProperty model
        if model = profile.favorites?[detail.rm_property_id]
          _.extend model, detail
          _favoriteProperty model

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

  _saveProperty = (model, save = true) ->
    return if !model or !model.rm_property_id
    rm_property_id = model.rm_property_id

    model.savedDetails ?= new rmapsPropertyFactory(rm_property_id)

    prop = service.pins[rm_property_id]

    if save
      if !prop
        _.extend model, service.pins[rm_property_id]
        service.pins[rm_property_id] = model
      model.savedDetails.isPinned = true
    else
      delete service.pins[rm_property_id]
      model.savedDetails.isPinned = false

  _favoriteProperty = (model) ->
    return if !model or !model.rm_property_id
    rm_property_id = model.rm_property_id

    if !model.savedDetails
      model.savedDetails = new rmapsPropertyFactory(rm_property_id)

    prop = service.favorites[rm_property_id]
    if !prop
      service.favorites[rm_property_id] = model
      model.savedDetails.isFavorite = true
    else
      delete service.favorites[rm_property_id]
      model.savedDetails.isFavorite = false

  _setFlags = (model) ->
    return if !model or !model.rm_property_id
    rm_property_id = model.rm_property_id

    model.savedDetails ?= new rmapsPropertyFactory(rm_property_id)
    model.savedDetails.isPinned = !!service.pins[rm_property_id]
    model.savedDetails.isFavorite = !!service.favorites[rm_property_id]

  _loadProperties = (col = service.pins) ->
    service.getProperties (_.pluck _.filter(col, (p) -> !p.rm_status?), 'rm_property_id'), 'filter'
    .then (response) ->
      for result in response.data
        _.extend col[result.rm_property_id], result

  _processPropertyPins = (models, needLoad) ->
    if needLoad
      _loadProperties()
      .then () ->
        $rootScope.$emit rmapsEventConstants.update.properties.pin,
          property: models[0],
          properties: service.pins
    else
      $rootScope.$emit rmapsEventConstants.update.properties.pin,
        property: models[0],
        properties: service.pins

    #post state to database
    toSave = _.mapValues service.pins, (model) -> model.savedDetails
    statePromise = $http.post(backendRoutes.userSession.updateState, properties_selected: toSave)
    _saveThrottler.invokePromise statePromise
    statePromise.error (data, status) ->
      $rootScope.$emit(rmapsEventConstants.alert, {type: 'danger', msg: data})

  #
  # Service API Definition
  #

  # will receive results from backend, which will be organzed either as
  #   standard results or cluster results, determined in backend by #of results returned
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

  service.pinProperty = (models) ->
    if !_.isArray models
      models = [ models ]

    # In case this is a list of models, determine if *any* of them are being pinned... if so, invoke the _loadProperties()
    needLoad = false
    _.each models, (model) ->
      if !model.savedDetails?.isPinned
        needLoad = true

      _saveProperty model, true

    _processPropertyPins models, needLoad

  service.unpinProperty = (models) ->
    if !_.isArray models
      models = [ models ]

    _.each models, (model) ->
      _saveProperty model, false

    _processPropertyPins models, false

  service.pinUnpinProperty = (models) ->
    if !_.isArray models
      models = [ models ]

    # In case this is a list of models, determine if *any* of them are being pinned...
    # if so, invoke the _loadProperties()
    needLoad = false
    _.each models, (model) ->
      if !model.savedDetails?.isPinned
        needLoad = true

      _saveProperty model, !model.savedDetails?.isPinned

    _processPropertyPins models, needLoad

  service.favoriteProperty = (model) ->
    _favoriteProperty model
    $rootScope.$emit rmapsEventConstants.update.properties.favorite,
      property: model,
      properties: service.favorites

    #post state to database
    toSave = _.mapValues service.favorites, (model) -> model.savedDetails
    statePromise = $http.post(backendRoutes.userSession.updateState, favorites: toSave)
    _saveThrottler.invokePromise statePromise
    statePromise.error (data, status) ->
      $rootScope.$emit(rmapsEventConstants.alert, {type: 'danger', msg: data})

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
