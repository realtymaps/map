app = require '../app.coffee'
Point = require('../../../../common/utils/util.geometries.coffee').Point

sprintf = require('sprintf-js').sprintf
require '../services/leafletObjectFetcher.coffee'

app.service 'rmapsResultsFormatterService', ($rootScope, $timeout, $filter, $log, $state, $location, rmapsParcelEnums,
  rmapsGoogleService, rmapsPropertiesService, rmapsFormattersService, uiGmapGmapUtil, rmapsEventConstants,
  rmapsLeafletObjectFetcherFactory, rmapsMainOptions, rmapsZoomLevelService) ->

  leafletDataMainMap = new rmapsLeafletObjectFetcherFactory('mainMap')
  limits = rmapsMainOptions.map

  class ResultsFormatter

    RESULTS_LIST_DEFAULT_LENGTH: 10
    LOAD_MORE_LENGTH: 10

    _isWithinBounds = (map, prop) ->
      pointBounds = rmapsGoogleService.GeoJsonTo.MultiPolygon
      .toBounds(prop.geometry or prop.geom_polys_json or prop.geom_point_json)

      isVisible = map.getBounds().intersects(pointBounds)
      return unless isVisible
      prop

    constructor: (@mapCtrl) ->
      _.extend @, rmapsFormattersService.Common
      _.extend @, google: rmapsGoogleService

      @mapCtrl.scope.isScrolling = false

      onScrolling = _.debounce ->
        if @mapCtrl?.scope?
          @mapCtrl.scope.isScrolling = true

      window.onscroll = onScrolling
      $timeout =>
        @mapCtrl.scope.isScrolling = false if(@mapCtrl.scope.isScrolling)
      , 100

      @reset = _.debounce =>
        $log.debug 'resultsFormatters.reset()'

        @mapCtrl.scope.resultsLimit = @RESULTS_LIST_DEFAULT_LENGTH
        @mapCtrl.scope.results = {}
        @lastSummaryIndex = 0
        @mapCtrl.scope.resultsPotentialLength = undefined
        @filterSummaryInBounds = undefined

        #make sure selectedResult is updated if it exists
        summary = @mapCtrl.scope.map?.markers?.filterSummary
        if @mapCtrl.scope.selectedResult? and summary[@mapCtrl.scope.selectedResult.rm_property_id]?
          delete @mapCtrl.scope.selectedResult.savedDetails
          angular.extend(@mapCtrl.scope.selectedResult, summary[@mapCtrl.scope.selectedResult.rm_property_id])
        @loadMore()
      , 5

      @mapCtrl.scope.resultsLimit = @RESULTS_LIST_DEFAULT_LENGTH
      @mapCtrl.scope.results = {}
      @mapCtrl.scope.resultsPotentialLength = undefined
      @mapCtrl.scope.resultsDescending = false
      @setOrReverseResultsPredicate('price')
      @lastSummaryIndex = 0
      @origLen = 0
      @postRepeat = null
      @mapCtrl.scope.resultsRepeatPerf =
        init: (postRepeat, scope) =>
          @postRepeat = postRepeat
        doDeleteLastTime: false

      @mapCtrl.scope.$watch 'map.markers.filterSummary', (newVal, oldVal) =>
        $log.debug 'resultsFormatter - watch filterSummary'

        return if newVal == oldVal
        @lastSummaryIndex = 0
        #what is special about this case where we do not use reset??
        @mapCtrl.scope.results = {}
        @loadMore()

    getResultsArray: =>
      _.values @mapCtrl.scope.results

    ###
    Disabling animation speeds up scrolling and makes it smoother by around 30~40ms
    ###
    getAdditionalClasses: (result) ->
      classes = ''
      classes += 'result-property-hovered' if result?.isMousedOver
      classes

    setOrReverseResultsPredicate: (predicate) =>
      if @mapCtrl.scope.resultsPredicate != predicate
        @mapCtrl.scope.resultsPredicate = predicate
      else
        # if they hit the same button again, invert the search order
        @mapCtrl.scope.resultsDescending = !@mapCtrl.scope.resultsDescending

    getSortClass: (toMatchSortStr) =>
      if toMatchSortStr != @mapCtrl.scope.resultsPredicate
        return ''
      sortClass = 'active-sort'
      return sortClass

    centerOn: (result) =>
      @zoomTo(result,false)

    zoomTo: (result, doChangeZoom = true) =>
      return if not result?.coordinates?

      resultCenter = new Point(result.coordinates[1],result.coordinates[0])
      old = _.cloneDeep @mapCtrl.scope.map.center
      resultCenter.zoom = old.zoom
      @mapCtrl.scope.map.center = resultCenter
      return unless doChangeZoom
      zoomLevel = @mapCtrl.scope.options.zoomThresh.addressParcel
      zoomLevel = @mapCtrl.scope.map.center.zoom if @mapCtrl.scope.map.center.zoom > @mapCtrl.scope.options.zoomThresh.addressParcel
      @mapCtrl.scope.map.center.zoom = zoomLevel

      resultCenter.zoom = 20 if @mapCtrl.scope.satMap?

    loadMore: =>
      #debugging
      @postRepeat.lastTime = new Date() if @postRepeat
      #end debugging
      if @loader
        $timeout.cancel @loader
      @loader = $timeout @throttledLoadMore, 20

    getAmountToLoad: () ->
      return @LOAD_MORE_LENGTH

    throttledLoadMore: (amountToLoad, loadedCtr = 0) =>
      $log.debug "throttledLoadMore()"

      amountToLoad = @getAmountToLoad()

      if !@filterSummaryInBounds and _.keys(@mapCtrl.scope.map.markers.filterSummary).length
        @filterSummaryInBounds = []
        _.each @mapCtrl.scope.map.markers.filterSummary, (prop) =>
          return unless prop
          @filterSummaryInBounds.push prop if _isWithinBounds(@mapCtrl.map, prop)

        @mapCtrl.scope.resultsPotentialLength = @filterSummaryInBounds.length

      return unless _.keys(@filterSummaryInBounds).length

      if not @mapCtrl.scope.results.length # only do this once (per map bound)
        _.each @filterSummaryInBounds, (summary) =>
          if @mapCtrl.layerFormatter.isVisible(@mapCtrl.scope, summary)
            @mapCtrl.scope.results[summary.rm_property_id] = summary

      @mapCtrl.scope.resultsLimit = Math.min @mapCtrl.scope.resultsLimit + amountToLoad, @mapCtrl.scope.resultsPotentialLength

      $log.debug "New results limit > #{@mapCtrl.scope.resultsLimit} / #{@mapCtrl.scope.resultsPotentialLength} <"

    showModel: (model) =>
      @click(@mapCtrl.scope.map.markers.filterSummary[model.rm_property_id]||model, window.event, 'map')

    click: (result, event, context) ->
      $state.go "property", { id: result.rm_property_id }

      maybeFetchCb = (showDetails) =>
        #start getting more data
        if showDetails
          rmapsPropertiesService.getPropertyDetail(@mapCtrl.scope.refreshState(
            map_results:
              selectedResultId: result.rm_property_id)
          , {rm_property_id: result.rm_property_id}, if result.rm_status then 'detail' else 'all')
          .then (data) =>
            return unless data
            $timeout () =>
              angular.extend @mapCtrl.scope.selectedResult, data
              $location.search 'property_id', result.rm_property_id
            , 50

        @mapCtrl.scope.Toggles.showDetails = showDetails
        @centerOn(result) if showDetails

      #immediatley show something
      @mapCtrl.scope.streetViewPanorama.status = 'OK'
      resultCenter = new Point(result.coordinates[1],result.coordinates[0])
      resultCenter.zoom = 20 if @mapCtrl.scope.satMap?
      @mapCtrl.scope.satMap.center= resultCenter

      if @mapCtrl.scope.selectedResult != result or not context
        @mapCtrl.scope.selectedResult = result
        #set the zoom back so it always is close to the property
        #immediatley turn off sat
        maybeFetchCb(true)
      else
        maybeFetchCb(false)
        @mapCtrl.scope.selectedResult = undefined

    clickSaveResultFromList: (result, event = {}) =>
      if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)
      wasSaved = result?.savedDetails?.isSaved
      @mapCtrl.saveProperty(result, leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject).then =>
        @reset()
        if wasSaved and !@mapCtrl.scope.results[result.rm_property_id]
          result.isMousedOver = undefined

    clickFavoriteResultFromList: (result, event = {}) =>
      if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)
      wasFavorite = result?.savedDetails?.isFavorite
      @mapCtrl.favoriteProperty(result, leafletDataMainMap.get(result.rm_property_id, 'filterSummary')?.lObject).then =>
        @reset()
        if wasFavorite and !@mapCtrl.scope.results[result.rm_property_id]
          result.isMousedOver = undefined
