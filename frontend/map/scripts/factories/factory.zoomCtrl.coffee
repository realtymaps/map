###globals _###
app = require '../app.coffee'
stampit = require 'stampit'

app.factory 'rmapsZoomLevelStateFactory', (rmapsZoomLevelService) ->

  stampit.init () ->

    zoomPath = @zoomPath || 'map.center.zoom'

    if @scope
      @scope.getDefaultLayerToolTip = (layerName) ->
        "Enable / Disable #{layerName} Layer"

      @scope.disableAddressButton = () =>
        zoom = rmapsZoomLevelService.getZoom(@scope)
        if zoom <= @scope.options.zoomThresh.addressButtonHide
          @scope.addressButtonLayerToolTip = "Zoom In to Enable Address Layer On/Off"
          return true

        @scope.addressButtonLayerToolTip = @scope.getDefaultLayerToolTip("Address")
        false

      @scope.disablePriceButton = () =>
        # when we are in the price range we are wanting to disable the ability
        # to turn it off
        ret = rmapsZoomLevelService.isPrice(null, @scope)
        @scope.priceButtonLayerToolTip = if ret
          "Zoom In to Enable Price Layer On/Off"
        else
          @scope.getDefaultLayerToolTip("Price")
        ret

      @scope.addressButtonLayerToolTip = @scope.getDefaultLayerToolTip("Address")
      @scope.priceButtonLayerToolTip = @scope.getDefaultLayerToolTip("Price")

    @isZoomLevel = (key, doSetState) ->
      if doSetState
        return rmapsZoomLevelService[key](_.get(@scope, zoomPath), @scope)
      rmapsZoomLevelService[key](@scope.map.center.zoom)

    @isAddressParcel = (doSetState) ->
      @isZoomLevel('isAddressParcel', doSetState)

    @isParcel = () ->
      @isZoomLevel('isParcel')

    @isAnyParcel = () ->
      @isParcel() or @isAddressParcel()

    @isBeyondCartoDb = () ->
      @isZoomLevel('isBeyondCartoDb')

    @showClientSideParcels = () ->
      ###
      isBeyondCartoDb is important as we are beyond the context of what
      cartodb can show us server side. We now will put the work load on the client for parcels.
      However, this is ok as we should be zoomed in a significant amount where (n) parcels should be
      smaller.
      ###
      (@isAddressParcel(true) or @isParcel()) and @isBeyondCartoDb()

    @showVectorPolys = () ->
      !@showClientSidePolys()

    return
