app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'


app.service 'Properties'.ourNs(), ['$rootScope', '$http', 'Property'.ourNs(), 'principal'.ourNs(),
  'events'.ourNs(), 'uiGmapPropMap', 'PromiseThrottler'.ourNs(),
  ($rootScope, $http, Property, principal, Events, PropMap, PromiseThrottler) ->
    #HASH to properties by rm_property_id
    #we may want to save details beyond just saving there fore it will be a hash pointing to an object
    savedProperties = {}

    detailThottler = new PromiseThrottler()
    filterThrottler = new PromiseThrottler()
    parcelThrottler = new PromiseThrottler()
    saveThrottler = new PromiseThrottler()

    $rootScope.$onRootScope Events.principal.login.success, () ->
      principal.getIdentity().then (identity) ->
        savedProperties = _.extend {}, identity.stateRecall.properties_selected

    # this convention for a combined service call helps elsewhere because we know how to get the path used
    # by this call, which means we can do things with alerts related to it
    getPropertyData = (pathId, hash, mapState, filters="") ->
      return null if !hash?
      $http.get("#{backendRoutes.properties[pathId]}?bounds=#{hash}#{filters}&#{mapState}", cache: true)

    getFilterSummary: (hash, mapState, filters="") ->
      filterThrottler.invokePromise getPropertyData('filterSummary', hash, mapState, filters)
      , http: {route: backendRoutes.properties.filterSummary }

    getParcelBase: (hash, mapState, filters="") ->
      parcelThrottler.invokePromise getPropertyData('parcelBase', hash, mapState, filters)
      , http: {route: backendRoutes.properties.parcelBase }

    getPropertyDetail: (mapState, rm_property_id, column_set) ->
      detailThottler.invokePromise $http.get("#{backendRoutes.properties.detail}?rm_property_id=#{rm_property_id}&columns=#{column_set}&#{mapState}", cache: true)
      , http: {route: backendRoutes.properties.detail }

    saveProperty: (model) =>
      return if not model or not model.rm_property_id
      rm_property_id = model.rm_property_id
      prop = savedProperties[rm_property_id]
      if not prop
        prop = new Property(rm_property_id, true, false, undefined)
        savedProperties[rm_property_id] = prop
        model.savedDetails = prop
      else
        prop.isSaved = !prop.isSaved
        unless prop.notes
          delete savedProperties[rm_property_id]
          #main dependency is layerFormatters.isVisible

      #post state to database
      promise = $http.post(backendRoutes.user.updateState, properties_selected: savedProperties)
      saveThrottler.invokePromise promise
      promise.error (data, status) -> $rootScope.$emit(Events.alert, {type: 'danger', msg: data})
      .then  ->
        prop

    getSavedProperties: ->
      savedProperties

    setSavedProperties: (props) ->
      savedProperties = props

    savedProperties: savedProperties
]
