stampit = require 'stampit'
app = require '../../../app.coffee'

###
  overall flow:
  if this.promise exists then the mutation has been handled.
###
app.factory 'rmapClusterMutation', (
$q
rmapsLayerFormattersService
rmapsPropertiesService
rmapsLayerUtil
) ->
  {MLS} = rmapsLayerFormattersService

  stampit.methods
    isClusterResults: () ->
      Object.prototype.toString.call(@data) is '[object Array]' and !@isEmptyData() and !@promise

    mutateCluster: () ->
      if @isClusterResults()
        @scope.map.markers.filterSummary = {}
        clusters = {}
        for k, model of @data
          # Need to ensure unique keys for markers so old ones get removed, new ones get added. Dashes must be removed.
          clusters["#{model.count}:#{model.lat}:#{model.lng}".replace('-','N')] = MLS.setMarkerManualClusterOptions(model)
        @scope.map.markers.backendPriceCluster = clusters

      @

  .compose(rmapsLayerUtil)
