stampit = require 'stampit'
app = require '../../../app.coffee'
_ = require 'lodash'


app.factory 'rmapSummaryMutation', (
$q
$log
rmapsLayerFormattersService
rmapsPropertiesService
rmapsZoomLevelStateFactory
) ->
  $log = $log.spawn 'rmapSummaryMutation'

  {setDataOptions, MLS} = rmapsLayerFormattersService

  _wrapGeomCenterJson = (obj) ->
    if !obj?.geometry_center?
      obj.geometry_center =
        coordinates: obj.coordinates
        type: obj.type
    obj

  _filterSaves = (model) ->
    model.savedDetails?.isPinned == true || model.savedDetails?.isFavorite == true

  _filterStatus = (properties, status) ->
    ret = _.filter(properties, 'status', status)
    _.remove(ret, _filterSaves)
    ret

  # build / format condo / appartment data
  _group = ({filterSummary, groups}) ->
    for key, group of groups
      if !group.grouped # skip if cached
        group.grouped = properties: _.values(group)
        group.grouped.name = key
        group.grouped.count = group.grouped.properties.length + 'U'
        group.grouped.forsale = _filterStatus(group.grouped.properties, 'for sale').length
        group.grouped.pending = _filterStatus(group.grouped.properties, 'pending').length
        group.grouped.sold = _filterStatus(group.grouped.properties, 'sold').length
        group.grouped.saves = _.filter(group.grouped.properties, _filterSaves).length
        group.grouped.notforsale = 0

        MLS.setMarkerPriceGroupOptions(group)

        first = _.find(group)
        group.coordinates = first.coordinates
        group.type = first.type
        _wrapGeomCenterJson(group)
        group.geometry = group.geometry_center

      filterSummary["#{group.grouped.name}:#{group.grouped.forsale}:#{group.grouped.pending}:#{group.grouped.sold}"] = group

  _special = ({filterSummary, specialKey}) ->
    special = {}
    for key, model of filterSummary
      if model.savedDetails?[specialKey] == true
        special[key] = model
        delete filterSummary[key] #NOTE this delete also protects against having double markers for saves and favorites

    if Object.keys(special).length then special else undefined

  _saves = (filterSummary) ->
    _special({filterSummary, specialKey: 'isPinned'})

  _favorites = (filterSummary) ->
    _special({filterSummary, specialKey: 'isFavorite'})

  stampit.methods

    mutateSummary: () ->
      if @isClusterResults()
        return
      overlays = @scope.map.layers.overlays
      Toggles = @scope.Toggles

      @scope.map.markers.backendPriceCluster = {}

      singletons = @data?.singletons || @data
      setDataOptions(singletons, MLS.setMarkerPriceOptions)

      filterSummary = {}

      for key, model of singletons
        _wrapGeomCenterJson model
        rmapsPropertiesService.updateProperty model
        filterSummary[key] = model

      _group({filterSummary, groups: @data?.groups})

      @scope.map.markers.saves = _saves(filterSummary)
      @scope.map.markers.favorites = _favorites(filterSummary)

      @scope.map.markers.filterSummary = filterSummary

      $log.debug @scope.map.markers.filterSummary

      # turn our price marker layer back on if zooming from parcel-level
      if @scope.zoomLevelService.isFromParcelZoom()
        Toggles.showPrices = true

      if !@isAnyParcel()
        overlays?.parcels?.visible = false
        Toggles.showAddresses = false
        overlays?.parcelsAddresses?.visible = false

      @

  .compose rmapsZoomLevelStateFactory
