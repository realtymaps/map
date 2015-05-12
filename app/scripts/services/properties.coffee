app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

app.service 'rmapsProperties', ['$rootScope', '$http', 'Property'.ourNs(), 'principal'.ourNs(),
  'events'.ourNs(), 'PromiseThrottler'.ourNs(), '$log'
  ($rootScope, $http, Property, principal, Events, PromiseThrottler, $log) ->
    #HASH to rmapsProperties by rm_property_id
    #we may want to save details beyond just saving there fore it will be a hash pointing to an object
    _savedrmapsProperties = {}

    _detailThrottler = new PromiseThrottler('detailThrottler')
    _filterThrottler = new PromiseThrottler('filterThrottler')
    _filterThrottlerGeoJson = new PromiseThrottler('filterThrottlerGeoJson')
    _filterThrottlerCluster = new PromiseThrottler('filterThrottlerCluster')
    _parcelThrottler = new PromiseThrottler('parcelThrottler')
    _saveThrottler = new PromiseThrottler('saveThrottler')
    _addressThrottler = new PromiseThrottler('addressThrottler')

    $rootScope.$onRootScope Events.principal.login.success, () ->
      principal.getIdentity().then (identity) ->
        _savedrmapsProperties = _.extend {}, identity.stateRecall.rmapsProperties_selected

    # this convention for a combined service call helps elsewhere because we know how to get the path used
    # by this call, which means we can do things with alerts related to it
    _getPropertyData = (pathId, hash, mapState, returnType, filters="", cache = true) ->
      return null if !hash?

      if returnType? and !_.isString(returnType)
        $log.error "returnType is not a string. returnType: #{returnType}"

      returnTypeStr = if returnType? then "&returnType=#{returnType}" else ''
      route = "#{backendRoutes.rmapsProperties[pathId]}?bounds=#{hash}#{returnTypeStr}#{filters}&#{mapState}"
      $http.get(route, cache: cache)

    _getFilterSummary = (hash, mapState, returnType, filters="", cache = true, throttler = _filterThrottler) ->
      throttler.invokePromise(
        _getPropertyData('filterSummary', hash, mapState, returnType, filters, cache)
        , http: {route: backendRoutes.rmapsProperties.filterSummary })

    service =

      getFilterSummary: (hash, mapState, filters="", cache = true) ->
        _getFilterSummary(hash, mapState, undefined, filters, cache)

      getFilterSummaryAsCluster: (hash, mapState, filters="", cache = true) ->
        _getFilterSummary(hash, mapState, 'cluster', filters, cache, _filterThrottlerCluster)

      getFilterSummaryAsGeoJsonPolys: (hash, mapState, filters="", cache = true) ->
        _getFilterSummary(hash, mapState, 'geojsonPolys', filters, cache, _filterThrottlerGeoJson)

      getParcelBase: (hash, mapState, cache = true) ->
        _parcelThrottler.invokePromise _getPropertyData(
          'parcelBase', hash, mapState, undefined, filters = '', cache)
        , http: {route: backendRoutes.rmapsProperties.parcelBase }

      getAddresses: (hash, mapState, cache = true) ->
        _addressThrottler.invokePromise _getPropertyData(
          'addresses', hash, mapState, undefined, filters = '', cache)
        , http: {route: backendRoutes.rmapsProperties.parcelBase }

      getPropertyDetail: (mapState, rm_property_id, column_set, cache = true) ->
        mapStateStr = if mapState? then "&#{mapState}" else ''
        url = "#{backendRoutes.rmapsProperties.detail}?rm_property_id=#{rm_property_id}&columns=#{column_set}#{mapStateStr}"
        _detailThrottler.invokePromise $http.get(url, cache: cache)
        , http: {route: backendRoutes.rmapsProperties.detail }

      saveProperty: (model) =>
        return if not model or not model.rm_property_id
        rm_property_id = model.rm_property_id
        prop = _savedrmapsProperties[rm_property_id]
        if not prop
          prop = new Property(rm_property_id, true, false, undefined)
          _savedrmapsProperties[rm_property_id] = prop
        else
          prop.isSaved = !prop.isSaved
          unless prop.notes
            delete _savedrmapsProperties[rm_property_id]
            #main dependency is layerFormatters.isVisible
        model.savedDetails = prop

        if !model.rm_status
          service.getPropertyDetail("", rm_property_id, "filter")
          .then (data) =>
            _.extend model, data

        #post state to database
        statePromise = $http.post(backendRoutes.user.updateState, rmapsProperties_selected: _savedrmapsProperties)
        _saveThrottler.invokePromise statePromise
        statePromise.error (data, status) -> $rootScope.$emit(Events.alert, {type: 'danger', msg: data})
        statePromise.then () ->
          prop

      getSavedrmapsProperties: ->
        _savedrmapsProperties

      setSavedrmapsProperties: (props) ->
        _savedrmapsProperties = props

      savedrmapsProperties: _savedrmapsProperties

    service
]
