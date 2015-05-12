app = require '../app.coffee'
Point = require('../../../../common/utils/util.geometries.coffee').Point

sprintf = require('sprintf-js').sprintf
require '../services/leafletObjectFetcher.coffee'

app.factory 'ResultsFormatter'.ourNs(), [
  '$rootScope', '$timeout', '$filter',
  '$log', 'ParcelEnums'.ourNs(), 'GoogleService'.ourNs(),
  'Properties'.ourNs(), 'FormattersService'.ourNs(), 'uiGmapGmapUtil', 'events'.ourNs(),
  'rmapsLeafletObjectFetcher', 'MainOptions'.ourNs(), 'ZoomLevel'.ourNs(),
  ($rootScope, $timeout, $filter,
  $log, ParcelEnums, GoogleService,
  Properties, FormattersService, uiGmapGmapUtil, Events,
  rmapsLeafletObjectFetcher, MainOptions, ZoomLevel) ->

    leafletDataMainMap = new rmapsLeafletObjectFetcher('mainMap')
    limits = MainOptions.map

    _forSaleClass = {}
    _forSaleClass[ParcelEnums.status.sold] = 'sold'
    _forSaleClass[ParcelEnums.status.pending] = 'pending'
    _forSaleClass[ParcelEnums.status.forSale] = 'forsale'
    _forSaleClass[ParcelEnums.status.notForSale] = 'notsale'
    _forSaleClass['saved'] = 'saved'
    _forSaleClass['default'] = ''

    _statusLabelClass = {}
    _statusLabelClass[ParcelEnums.status.sold] = 'label-sold-property'
    _statusLabelClass[ParcelEnums.status.pending] = 'label-pending-property'
    _statusLabelClass[ParcelEnums.status.forSale] = 'label-sale-property'
    _statusLabelClass[ParcelEnums.status.notForSale] = 'label-notsale-property'
    _statusLabelClass['saved'] = 'label-saved-property'
    _statusLabelClass['default'] = ''

    _resultOrModel = (result, model, resultsHash) ->
      if result
        return result
      if !model or !model?.rm_property_id or !resultsHash
        return undefined
      resultsHash[model.rm_property_id]

    _handleMouseEventToMap = (mapCtrl, eventName, result, model, resultsHash, originator) ->
      event = window.event
      result = _resultOrModel(result, model, resultsHash)
      return unless result

      if model != result and model.hasOwnProperty('isMousedOver')
        result.isMousedOver = model.isMousedOver  #THIS IS important as the model is not always the same as the result (reference wise) rmaps ngReplacements

      #need event, lObject, model, modelName, layerName, type
      modelName = result.rm_property_id
      layerName = if ZoomLevel.isPrice(mapCtrl.scope.map.center.zoom) then 'filterSummary' else 'filterSummaryPoly'
      originator = if originator? then originator else 'results'

      payload = if layerName != 'filterSummaryPoly' then leafletDataMainMap.get(modelName) else leafletDataMainMap.get(modelName, layerName)
      {lObject, type} = payload
      mapCtrl.eventHandle[eventName](event, lObject, result, modelName, layerName, type, originator, 'results')

    class ResultsFormatter

      _isWithinBounds = (map, prop) =>
        pointBounds = GoogleService.GeoJsonTo.MultiPolygon.toBounds(prop.geom_polys_json)
        isVisible = map.getBounds().intersects(pointBounds)
        return unless isVisible
        prop

      constructor: (@mapCtrl) ->
        _.extend @, FormattersService.Common
        _.extend @, FormattersService.Google

        @mapCtrl.scope.isScrolling = false

        onScrolling = _.debounce ->
          @mapCtrl.scope.isScrolling = true

        window.onscroll = onScrolling
        $timeout =>
          @mapCtrl.scope.isScrolling = false if(@mapCtrl.scope.isScrolling)
        , 100

        @reset = _.debounce =>
          @mapCtrl.scope.resultsLimit = 10
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
        @mapCtrl.scope.resultsLimit = 10
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
          return if newVal == oldVal
          @lastSummaryIndex = 0
          #what is special about this case where we do not use reset??
          @mapCtrl.scope.results = {}
          @loadMore()

        @mapCtrl.scope.$watch 'Toggles.showResults', (newVal, oldVal) =>
          return if newVal == oldVal
          @loadMore()

      getResultsArray: =>
        _.values @mapCtrl.scope.results
      ###
      Disabling animation speeds up scrolling and makes it smoother by around 30~40ms
      ###
      getAdditionalClasses: (result) =>
        classes = ""
        classes += "result-property-hovered" if result?.isMousedOver
        classes

      setOrReverseResultsPredicate: (predicate) =>
        if @mapCtrl.scope.resultsPredicate != predicate
          @mapCtrl.scope.resultsPredicate = predicate
        else
          # if they hit the same button again, invert the search order
          @mapCtrl.scope.resultsDescending = !@mapCtrl.scope.resultsDescending

      isSavedResult:(result) ->
        result?.savedDetails?.isSaved == true

      getCurrentOwnersTitle: (result) =>
        title = "Current Owner"
        if @hasMultipleOwners(result)
          title += "s"
        title
      hasMultipleOwners: (result) ->
        if result.owner_name2? and result.owner_name?
          return true
        return false

      getSortClass: (toMatchSortStr) =>
        if toMatchSortStr != @mapCtrl.scope.resultsPredicate
          return ''
        sortClass = 'active-sort fa-chevron-circle-'
        sortClass += if @mapCtrl.scope.resultsDescending then 'down' else 'up'
        return sortClass

      getForSaleClass: (result) ->
        return unless result
        soldClass = _forSaleClass['saved'] if result.savedDetails?.isSaved
        return soldClass or _forSaleClass[result.rm_status] or _forSaleClass['default']

      getStatusLabelClass: (result, ignoreSavedStatus=false) ->
        return unless result
        soldClass = _statusLabelClass['saved'] if result.savedDetails?.isSaved && !ignoreSavedStatus
        return soldClass or _statusLabelClass[result.rm_status] or _statusLabelClass['default']

      showSoldDate: (result) ->
        return false unless result
        return (result?.rm_status=='recently sold'||result.rm_status=='not for sale') && result.close_date

      sendSnail: (result) ->
        $rootScope.$emit Events.snail.initiateSend, result

      centerOn: (result) =>
        @zoomTo(result,false)

      zoomTo: (result, doChangeZoom = true) =>
        return if !result or not result.geom_point_json?
        resultCenter = new Point(result.coordinates[1],result.coordinates[0])
        old = _.cloneDeep @mapCtrl.scope.map.center
        resultCenter.zoom = old.zoom
        @mapCtrl.scope.map.center = resultCenter
        return unless doChangeZoom
        zoomLevel = @mapCtrl.scope.options.zoomThresh.addressParcel
        zoomLevel = @mapCtrl.scope.map.center.zoom if @mapCtrl.scope.map.center.zoom > @mapCtrl.scope.options.zoomThresh.addressParcel
        @mapCtrl.scope.map.center.zoom = zoomLevel

        resultCenter.zoom = 20 if @mapCtrl.scope.satMap?

      getPriceLabel: (status) ->
        if (status =='recently sold'|| status=='not for sale')
          label = ''
        else
          label = 'asking:'
        return label

      getCityStateZip: (model, owner=false) ->
        if !model?
          return ""
        prefix = if owner then "owner_" else ""
        csz = "#{model[prefix+"city"]}"
        if model[prefix+"state"]
          csz += ", #{model[prefix+"state"]}"
        if model[prefix+"zip"]
          csz += " #{model[prefix+"zip"]}"
        return csz

      showListingData: (model) ->
        return false if not model
        model.listing_age!=null || model.mls_close_date || model.original_price || model.mls_close_price

      showSalesData: (model) ->
        return false if not model
        model.mortgage_amount || model.mortgage_date || @showIfDifferentFrom(model, 'sale', 'mls_close') || @showIfDifferentFrom(model, 'prior_sale', 'mls_close')

      showIfDifferentFrom: (model, prefix, differentFromPrefix) ->
        return false if !model || !prefix || !differentFromPrefix
        prefix += '_'
        differentFromPrefix += '_'
        # differing prices or >= 30 days difference in sale date
        if (model[prefix+"date"] && !model[differentFromPrefix+"date"]) || model[prefix+"price"] != model[differentFromPrefix+"price"]
          return true
        if !model[prefix+"date"]
          return false
        millis1 = new Date(model[differentFromPrefix+"date"].toLocaleString()).getTime()
        millis2 = new Date(model[prefix+"date"].toLocaleString()).getTime()
        return Math.abs(millis1-millis2) > 30*86400000

      loadMore: =>
        #debugging
        return unless @mapCtrl.scope.Toggles.showResults
        @postRepeat.lastTime = new Date() if @postRepeat
        #end debugging
        if @loader
          $timeout.cancel @loader
        @loader = $timeout @throttledLoadMore, 20

      getAmountToLoad: _.memoize (totalHeight) ->
        cardHeight = 95 #we really need to somehow combine css constants and js constants
        numberOfCards = Math.round totalHeight / cardHeight
        #min height to keep scrolling
        numberOfCards

      throttledLoadMore: (amountToLoad, loadedCtr = 0) =>
        unless @resultsContainer
          @resultsContainer = document.getElementById(@mapCtrl.scope.resultsListId)
        return if not @resultsContainer or not @resultsContainer.offsetHeight > 0
        amountToLoad = @getAmountToLoad(@resultsContainer.offsetHeight) unless amountToLoad
        return unless amountToLoad

        if !@filterSummaryInBounds and _.keys(@mapCtrl.scope.map.markers.filterSummary).length
          @filterSummaryInBounds = []
          _.each @mapCtrl.scope.map.markers.filterSummary, (prop) =>
            return unless prop
            @filterSummaryInBounds.push prop if _isWithinBounds(@mapCtrl.map, prop)

          @mapCtrl.scope.resultsPotentialLength = @filterSummaryInBounds.length

        return unless _.keys(@filterSummaryInBounds).length

        if not @mapCtrl.scope.results.length # only do this once (per map bound)
          _.each @filterSummaryInBounds, (summary) =>
            if @mapCtrl.layerFormatter.isVisible(summary)
              @mapCtrl.scope.results[summary.rm_property_id] = summary

        @mapCtrl.scope.resultsLimit += amountToLoad

      showModel: (model) =>
        @click(@mapCtrl.scopeM().markers.filterSummary[model.rm_property_id]||model, window.event, 'map')

      click: (result, event, context) =>
        maybeFetchCb = (showDetails) =>
          #start getting more data
          if showDetails
            Properties.getPropertyDetail(@mapCtrl.refreshState(
              map_results:
                selectedResultId: result.rm_property_id)
            , result.rm_property_id, if result.rm_status then "detail" else "all")
            .then (data) =>
              return unless data
              $timeout () =>
                angular.extend @mapCtrl.scope.selectedResult, data
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

      mouseenter: (result, model, originator) =>
        _handleMouseEventToMap(@mapCtrl, 'mouseover', result, model, @mapCtrl.scope.results, originator)

      mouseleave: (result, model, originator) =>
        # return if @lastResultMouseLeave == (result or model)
        # @lastResultMouseLeave = result or model
        _handleMouseEventToMap(@mapCtrl, 'mouseout', result, model, @mapCtrl.scope.results, originator)

      clickSaveResultFromList: (result, eventOpts) =>
        event = eventOpts.$event
        if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)
        wasSaved = result?.savedDetails?.isSaved
        @mapCtrl.saveProperty(result).then =>
          @reset()
          if wasSaved and !@mapCtrl.scope.results[result.rm_property_id]
            result.isMousedOver = undefined

]
