app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'


app.service 'Properties'.ourNs(), ['$rootScope', '$http', 'Property'.ourNs(), 'principal'.ourNs(),
  ($rootScope, $http, Property, principal) ->
    #HASH to properties by rm_property_id
    #we may want to save details beyond just saving there fore it will be a hash pointing to an object
    savedProperties = {}

    principal.getIdentity().then (identity) ->
      savedProperties = _.extend savedProperties, identity.stateRecall.properties_selected

    getParcelBase: (hash, mapState) ->
      $http.get("#{backendRoutes.parcelBase}?bounds=#{hash}&#{mapState}")

    getFilterSummary: (hash, filters, mapState) ->
      $http.get("#{backendRoutes.filterSummary}?bounds=#{hash}#{filters}&#{mapState}")

    saveProperty: (model) =>
      return if not model or not model.rm_property_id
      rm_property_id = model.rm_property_id
      prop = savedProperties[rm_property_id]
      if not prop
        prop = new Property(rm_property_id, true, false, undefined)
        savedProperties[rm_property_id] = prop
      else
        prop.isSaved = !prop.isSaved
        delete savedProperties[rm_property_id]

      #post state to database
      promise = $http.post(backendRoutes.updateState, properties_selected: savedProperties)
      promise.error (data, status) ->
#        $rootScope.alerts.push
#          type: 'danger'
#          msg: data
      promise

    getSavedProperties: ->
      savedProperties

    setSavedProperties: (props) ->
      savedProperties = props

    savedProperties: savedProperties
]
