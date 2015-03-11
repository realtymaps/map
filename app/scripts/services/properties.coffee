app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'


app.service 'Properties'.ourNs(), ['$rootScope', '$http', 'Property'.ourNs(), 'principal'.ourNs(),
  'events'.ourNs(), 'uiGmapPropMap', 'PromiseThrottler'.ourNs(),
  ($rootScope, $http, Property, principal, Events, PropMap, PromiseThrottler) ->
    #HASH to properties by rm_property_id
    #we may want to save details beyond just saving there fore it will be a hash pointing to an object
    savedProperties = {}

    detailThrottler = new PromiseThrottler()
    filterThrottler = new PromiseThrottler()
    parcelThrottler = new PromiseThrottler()
    saveThrottler = new PromiseThrottler()

    $rootScope.$onRootScope Events.principal.login.success, () ->
      principal.getIdentity().then (identity) ->
        savedProperties = _.extend {}, identity.stateRecall.properties_selected

    # this convention for a combined service call helps elsewhere because we know how to get the path used
    # by this call, which means we can do things with alerts related to it
    getPropertyData = (pathId, hash, mapState, filters="", cache = true) ->
      return null if !hash?
      $http.get("#{backendRoutes.properties[pathId]}?bounds=#{hash}#{filters}&#{mapState}", cache: cache)

    service =
      getFilterSummary: (hash, mapState, filters="", cache = true) ->
        filterThrottler.invokePromise getPropertyData('filterSummary', hash, mapState, filters, cache)
        , http: {route: backendRoutes.properties.filterSummary }

      getParcelBase: (hash, mapState, cache = true) ->
        parcelThrottler.invokePromise getPropertyData('parcelBase', hash, mapState, filters = '', cache)
        , http: {route: backendRoutes.properties.parcelBase }

      getPropertyDetail: (mapState, rm_property_id, column_set, cache = true) ->
        mapStateStr = if mapState? then "&#{mapState}" else ''
        url = "#{backendRoutes.properties.detail}?rm_property_id=#{rm_property_id}&columns=#{column_set}#{mapStateStr}"
        detailThrottler.invokePromise $http.get(url, cache: cache)
        , http: {route: backendRoutes.properties.detail }

      saveProperty: (model) =>
        return if not model or not model.rm_property_id
        rm_property_id = model.rm_property_id
        prop = savedProperties[rm_property_id]
        if not prop
          prop = new Property(rm_property_id, true, false, undefined)
          savedProperties[rm_property_id] = prop
        else
          prop.isSaved = !prop.isSaved
          unless prop.notes
            delete savedProperties[rm_property_id]
            #main dependency is layerFormatters.isVisible
        model.savedDetails = prop

        if !model.rm_status
          service.getPropertyDetail("", rm_property_id, "filter")
          .then (data) =>
            _.extend model, data

        #post state to database
        statePromise = $http.post(backendRoutes.user.updateState, properties_selected: savedProperties)
        saveThrottler.invokePromise statePromise
        statePromise.error (data, status) -> $rootScope.$emit(Events.alert, {type: 'danger', msg: data})
        statePromise.then () ->
          return prop

      getSavedProperties: ->
        savedProperties

      setSavedProperties: (props) ->
        savedProperties = props

      savedProperties: savedProperties

    return service
]
