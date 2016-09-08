NgLeafletCenter = require('../../../../common/utils/util.geometries.coffee').NgLeafletCenter
app = require '../app.coffee'

app.service 'rmapsEventsHandlerInternalsService', (
rmapsMainOptions
rmapsNgLeafletHelpersService
rmapsPropertiesService
rmapsPopupLoaderService
$log) ->

  $log = $log.spawn("map:rmapsEventsHandlerInternalsService")

  inject = ({mapCtrl, mapPath}) ->

    $scope = mapCtrl.scope

    handleManualMarkerCluster = (model) ->
      if model.markerType == 'cluster'
        center = NgLeafletCenter(model)
        center.setZoom($scope[mapPath].center.zoom + 1)
        $scope[mapPath].center = center
        return true
      false

    canShowQuickView = (model) ->
      model.status || model.grouped

    getPropertyDetail = (opts) ->
      rmapsPropertiesService.getPropertyDetail(null, opts, 'id')
      .then (data) ->
        model = data.mls?[0] || data.county?[0]
        return if !model
        $scope.formatters.results.showModel(model)

    openWindow = (model) ->
      opts = {map: mapCtrl.map, model}
      $log.debug "openWindow", model
      # Do not show infowindow for parcels without property data
      if canShowQuickView(model)
        return rmapsPopupLoaderService.load(opts)

      opts = if model.rm_property_id?
        rm_property_id: model.rm_property_id
        no_alert: true
      else
        geometry_center: model.geometry_center

      getPropertyDetail(opts)

    closeWindow = ->
      rmapsPopupLoaderService.close()

    {
      handleManualMarkerCluster
      canShowQuickView
      getPropertyDetail
      openWindow
      closeWindow
    }

  {
    limits: rmapsMainOptions.map
    events:
      marker: rmapsNgLeafletHelpersService.events.markerEvents
      geojson:rmapsNgLeafletHelpersService.events.geojsonEvents
      last:
        mouseover:null
        last: null
    inject
  }
