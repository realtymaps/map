###globals _###
app = require '../app.coffee'
stampit = require 'stampit'

app.factory 'rmapsZoomLevelStateFactory', (rmapsZoomLevelService) ->
  stampit.init () ->

    zoomPath = @zoomPath || 'map.center.zoom'

    if @scope
      @scope.doShowAddressButton = () =>
        zoom = rmapsZoomLevelService.getZoom(@scope)
        if zoom <= @scope.options.zoomThresh.addressButtonHide
          return false
        true


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
