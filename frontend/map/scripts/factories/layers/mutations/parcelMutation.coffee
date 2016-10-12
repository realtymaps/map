stampit = require 'stampit'
app = require '../../../app.coffee'

app.factory 'rmapParcelMutation', (
$q
$log
$timeout
rmapsZoomLevelStateFactory
rmapsPropertiesService
rmapsLayerFormattersService
rmapsLayerUtil
) ->
  $log = $log.spawn 'rmapParcelMutation'
  stampit.methods
    handleGeoJsonResults: (data) ->
      # clone (truned off), ui-leaflet, leaflet
      rmapsPropertiesService.getFilterSummaryAsGeoJsonPolys(@hash, @mapState, @filters, data)
      .then (data) =>
        return if @isEmptyData()

        $log.debug -> "@@@@ data @@@@"
        $log.debug -> data
        @scope.map.geojson.filterSummaryPoly =
          data: data
          style: rmapsLayerFormattersService.Parcels.getStyle

    mutateParcel: () ->
      if !@isAnyParcel()
        return $q.resolve()

      data = if @data?.singletons? then @data?.singletons else @data

      @handleGeoJsonResults(data)

  .compose rmapsZoomLevelStateFactory, rmapsLayerUtil
