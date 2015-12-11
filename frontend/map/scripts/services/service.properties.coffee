app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsPropertiesService', ($rootScope, $http, rmapsProperty, rmapsprincipal,
  rmapsevents, rmapsPromiseThrottler, $log) ->

  $log = $log.spawn("map:rmapsPropertiesService")

  #HASH to properties by rm_property_id
  #we may want to save details beyond just saving there fore it will be a hash pointing to an object
  _savedProperties = {}
  _favoriteProperties = {}

  _detailThrottler = new rmapsPromiseThrottler('detailThrottler')
  _filterThrottler = new rmapsPromiseThrottler('filterThrottler')
  _filterThrottlerGeoJson = new rmapsPromiseThrottler('filterThrottlerGeoJson')
  _filterThrottlerCluster = new rmapsPromiseThrottler('filterThrottlerCluster')
  _parcelThrottler = new rmapsPromiseThrottler('parcelThrottler')
  _saveThrottler = new rmapsPromiseThrottler('saveThrottler')
  _addressThrottler = new rmapsPromiseThrottler('addressThrottler')

  _prependAmpersand = (str) ->
    if str then '&' + str else ''
  # Reset the properties hash when switching profiles
  $rootScope.$onRootScope rmapsevents.principal.profile.updated, (event, profile) ->

    propertyIds = _.union _.keys(profile.properties_selected), _.keys(profile.favorites)

    service.getProperties propertyIds, 'filter'
    .then ({data}) ->
      for detail in data
        if model = profile.properties_selected[detail.rm_property_id]
          _.extend model, detail
          _saveProperty model
        if model = profile.favorites?[detail.rm_property_id]
          _.extend model, detail
          _favoriteProperty model

      $rootScope.$emit rmapsevents.map.properties.pin, _savedProperties
      $rootScope.$emit rmapsevents.map.properties.favorite, _favoriteProperties

  _getState = (mapState = {}, filters = {}) ->
    # $log.debug "mapState: #{JSON.stringify mapState}"
    # $log.debug "filters: #{JSON.stringify filters}"
    _.extend {}, mapState,
      filters: filters

  # this convention for a combined service call helps elsewhere because we know how to get the path used
  # by this call, which means we can do things with alerts related to it
  _getPropertyData = (pathId, hash, mapState, returnType, filters, cache = true) ->
    return null if !hash?

    bodyExtensions = {}

    if returnType? and !_.isString(returnType)
      $log.error "returnType is not a string. returnType: #{returnType}"

    if $rootScope.propertiesInShapes and returnType#is drawnShapes filterSummary
      pathId = 'drawnShapes'
      if $rootScope.neighbourhoodsListIsOpen
        bodyExtensions.isNeighbourhood = true

    route = backendRoutes.properties[pathId]
    if !window.isTest
      $log.debug("filters: #{JSON.stringify filters}")
      $log.debug mapState
      $log.log(route)

    $http.post(route, _.extend({}, bodyExtensions,
      bounds: hash
      returnType: returnType
      state: _getState(mapState, filters))
    , cache: cache)

  _getFilterSummary = (hash, mapState, returnType, filters, cache = true, throttler = _filterThrottler) ->
    throttler.invokePromise(
      _getPropertyData('filterSummary', hash, mapState, returnType, filters, cache)
      , http: {route: backendRoutes.properties.filterSummary })

  _saveProperty = (model) ->
    return if not model or not model.rm_property_id
    rm_property_id = model.rm_property_id

    if !model.savedDetails
      model.savedDetails = new rmapsProperty(rm_property_id)

    prop = _savedProperties[rm_property_id]
    if not prop
      _savedProperties[rm_property_id] = model
      model.savedDetails.isSaved = true
      if !model.rm_status
        service.getProperties model.rm_property_id, 'filter'
        .then (result) ->
          _.extend model, result.data[0]
    else
      delete _savedProperties[rm_property_id]
      model.savedDetails.isSaved = false

  _favoriteProperty = (model) ->
    return if not model or not model.rm_property_id
    rm_property_id = model.rm_property_id

    if !model.savedDetails
      model.savedDetails = new rmapsProperty(rm_property_id)

    prop = _favoriteProperties[rm_property_id]
    if not prop
      _favoriteProperties[rm_property_id] = model
      model.savedDetails.isFavorite = true
      if !model.rm_status
        service.getProperties model.rm_property_id, 'filter'
        .then (result) ->
          _.extend model, result.data[0]
    else
      delete _favoriteProperties[rm_property_id]
      model.savedDetails.isFavorite = false

  service =

    # will receive results from backend, which will be organzed either as
    #   standard results or cluster results, determined in backend by #of results returned
    getFilterResults: (hash, mapState, filters, cache = true) ->
      _getFilterSummary(hash, mapState, 'clusterOrDefault', filters, cache)

    getFilterSummary: (hash, mapState, filters, cache = true) ->
      _getFilterSummary(hash, mapState, undefined, filters, cache)

    getFilterSummaryAsCluster: (hash, mapState, filters, cache = true) ->
      _getFilterSummary(hash, mapState, 'cluster', filters, cache, _filterThrottlerCluster)

    getFilterSummaryAsGeoJsonPolys: (hash, mapState, filters, cache = true) ->
      _getFilterSummary(hash, mapState, 'geojsonPolys', filters, cache, _filterThrottlerGeoJson)

    getParcelBase: (hash, mapState, cache = true) ->
      _parcelThrottler.invokePromise _getPropertyData(
        'parcelBase', hash, mapState, undefined, undefined, cache)
      , http: {route: backendRoutes.properties.parcelBase }

    getAddresses: (hash, mapState, cache = true) ->
      _addressThrottler.invokePromise _getPropertyData(
        'addresses', hash, mapState, undefined, undefined, cache)
      , http: {route: backendRoutes.properties.parcelBase }

    getPropertyDetail: (mapState, queryObj, columns, cache = true) ->
      promise =
        $http.post(backendRoutes.properties.detail,
        _.extend({}, queryObj,{ state: _getState(mapState), columns: columns }), cache: cache)
      _detailThrottler.invokePromise(promise, http: route: backendRoutes.properties.detail)

    getProperties: (ids, columns) ->
      $http.post backendRoutes.properties.details, rm_property_id: ids, columns: columns

    saveProperty: (model) ->
      _saveProperty model
      $rootScope.$emit rmapsevents.map.properties.pin, _savedProperties

      #post state to database
      toSave = _.mapValues _savedProperties, (model) -> model.savedDetails
      statePromise = $http.post(backendRoutes.userSession.updateState, properties_selected: toSave)
      _saveThrottler.invokePromise statePromise
      statePromise.error (data, status) -> $rootScope.$emit(rmapsevents.alert, {type: 'danger', msg: data})

    favoriteProperty: (model) ->
      _favoriteProperty model
      $rootScope.$emit rmapsevents.map.properties.favorite, _favoriteProperties

      #post state to database
      toSave = _.mapValues _favoriteProperties, (model) -> model.savedDetails
      statePromise = $http.post(backendRoutes.userSession.updateState, favorites: toSave)
      _saveThrottler.invokePromise statePromise
      statePromise.error (data, status) -> $rootScope.$emit(rmapsevents.alert, {type: 'danger', msg: data})

    getSavedProperties: ->
      _savedProperties

    getFavoriteProperties: ->
      _favoriteProperties

    setSavedProperties: (props) ->
      _savedProperties = props

    # Map calls this to update property objects
    updateProperty: (model) ->
      if prop = _savedProperties[model?.rm_property_id]
        _savedProperties[model.rm_property_id] = model
        if !model.savedDetails
          model.savedDetails = prop.savedDetails

      if prop = _favoriteProperties[model?.rm_property_id]
        _favoriteProperties[model.rm_property_id] = model
        if !model.savedDetails
          model.savedDetails = prop.savedDetails
        else
          _.extend model.savedDetails, prop.savedDetails

    savedProperties: _savedProperties

  service
