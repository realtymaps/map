app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsProperties', ($rootScope, $http, rmapsProperty, rmapsprincipal,
  rmapsevents, rmapsPromiseThrottler, $log) ->

    #HASH to properties by rm_property_id
    #we may want to save details beyond just saving there fore it will be a hash pointing to an object
    _savedProperties = {}

    _detailThrottler = new rmapsPromiseThrottler('detailThrottler')
    _filterThrottler = new rmapsPromiseThrottler('filterThrottler')
    _filterThrottlerGeoJson = new rmapsPromiseThrottler('filterThrottlerGeoJson')
    _filterThrottlerCluster = new rmapsPromiseThrottler('filterThrottlerCluster')
    _parcelThrottler = new rmapsPromiseThrottler('parcelThrottler')
    _saveThrottler = new rmapsPromiseThrottler('saveThrottler')
    _addressThrottler = new rmapsPromiseThrottler('addressThrottler')

    $rootScope.$onRootScope rmapsevents.principal.login.success, () ->
      rmapsprincipal.getIdentity().then (identity) ->
        _savedPropertie = []
        if identity.currentProfileId and identity.profiles?.length
          currentProfile = identity.profiles[identity.currentProfileId]

        if currentProfile
          _savedProperties = _.extend {}, currentProfile.properties_selected

    # this convention for a combined service call helps elsewhere because we know how to get the path used
    # by this call, which means we can do things with alerts related to it
    _getPropertyData = (pathId, hash, mapState, returnType, filters='', cache = true) ->
      return null if !hash?

      if returnType? and !_.isString(returnType)
        $log.error "returnType is not a string. returnType: #{returnType}"

      returnTypeStr = if returnType? then "&returnType=#{returnType}" else ''
      route = "#{backendRoutes.properties[pathId]}?bounds=#{hash}#{returnTypeStr}#{filters}&#{mapState}"
      $http.get(route, cache: cache)

    _getFilterSummary = (hash, mapState, returnType, filters='', cache = true, throttler = _filterThrottler) ->
      throttler.invokePromise(
        _getPropertyData('filterSummary', hash, mapState, returnType, filters, cache)
        , http: {route: backendRoutes.properties.filterSummary })

    service =

      # will receive results from backend, which will be organzed either as
      #   standard results or cluster results, determined in backend by #of results returned
      getFilterResults: (hash, mapState, filters='', cache = true) ->
        _getFilterSummary(hash, mapState, 'clusterOrDefault', filters, cache)

      getFilterSummary: (hash, mapState, filters='', cache = true) ->
        _getFilterSummary(hash, mapState, undefined, filters, cache)

      getFilterSummaryAsCluster: (hash, mapState, filters='', cache = true) ->
        _getFilterSummary(hash, mapState, 'cluster', filters, cache, _filterThrottlerCluster)

      getFilterSummaryAsGeoJsonPolys: (hash, mapState, filters='', cache = true) ->
        _getFilterSummary(hash, mapState, 'geojsonPolys', filters, cache, _filterThrottlerGeoJson)

      getParcelBase: (hash, mapState, cache = true) ->
        _parcelThrottler.invokePromise _getPropertyData(
          'parcelBase', hash, mapState, undefined, filters = '', cache)
        , http: {route: backendRoutes.properties.parcelBase }

      getAddresses: (hash, mapState, cache = true) ->
        _addressThrottler.invokePromise _getPropertyData(
          'addresses', hash, mapState, undefined, filters = '', cache)
        , http: {route: backendRoutes.properties.parcelBase }

      getPropertyDetail: (mapState, rm_property_id, column_set, cache = true) ->
        mapStateStr = if mapState? then "&#{mapState}" else ''
        url = "#{backendRoutes.properties.detail}?rm_property_id=#{rm_property_id}&columns=#{column_set}#{mapStateStr}"
        _detailThrottler.invokePromise $http.get(url, cache: cache)
        , http: {route: backendRoutes.properties.detail }

      saveProperty: (model) ->
        return if not model or not model.rm_property_id
        rm_property_id = model.rm_property_id
        prop = _savedProperties[rm_property_id]
        if not prop
          prop = new rmapsProperty(rm_property_id, true, false, undefined)
          _savedProperties[rm_property_id] = prop
        else
          prop.isSaved = !prop.isSaved
          unless prop.notes
            delete _savedProperties[rm_property_id]
            #main dependency is layerFormatters.isVisible
        model.savedDetails = prop

        if !model.rm_status
          service.getPropertyDetail('', rm_property_id, 'filter')
          .then (data) ->
            _.extend model, data

        #post state to database
        statePromise = $http.post(backendRoutes.userSession.updateState, properties_selected: _savedProperties)
        _saveThrottler.invokePromise statePromise
        statePromise.error (data, status) -> $rootScope.$emit(rmapsevents.alert, {type: 'danger', msg: data})
        statePromise.then () ->
          prop

      getSavedProperties: ->
        _savedProperties

      setSavedProperties: (props) ->
        _savedProperties = props

      savedProperties: _savedProperties

    service
