app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf


app.factory 'ResultsFormatter'.ourNs(), [
  '$timeout', '$filter', 'Logger'.ourNs(), 'ParcelEnums'.ourNs(), 'GoogleService'.ourNs(),
  'Properties'.ourNs(), 'FormattersService'.ourNs(),
  ($timeout, $filter, $log, ParcelEnums, GoogleService, Properties, FormattersService) ->

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

    #TODO: BaseObject should really come from require not window.. same w/ PropMap
    class ResultsFormatter extends BaseObject
      @include FormattersService.Common
      @include FormattersService.Google
      constructor: (@mapCtrl) ->
        super()
        @mapCtrl.scope.isScrolling = false

        onScrolling = _.debounce ->
          @mapCtrl.scope.isScrolling = true

        window.onscroll = onScrolling
        $timeout =>
          @mapCtrl.scope.isScrolling = false if(@mapCtrl.scope.isScrolling)
        , 100

        @reset = _.debounce =>
          @mapCtrl.scope.resultsLimit = 10
          @mapCtrl.scope.results = []
          @lastSummaryIndex = 0
          @mapCtrl.scope.resultsPotentialLength = undefined
          @filterSummaryInBounds = undefined
          @loadMore()
        , 5
        @mapCtrl.scope.resultsLimit = 10
        @mapCtrl.scope.results = []
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

        @mapCtrl.scope.$watch 'layers.filterSummary', (newVal, oldVal) =>
          return if newVal == oldVal
          @lastSummaryIndex = 0
          @mapCtrl.scope.results = []
          @loadMore()

        @mapCtrl.scope.$watch 'Toggles.showResults', (newVal, oldVal) =>
          return if newVal == oldVal
          @loadMore()

      ###
      Disabling animation speeds up scrolling and makes it smoother by around 30~40ms
      ###
      maybeAnimate: =>
        "animated slide-down" if @mapCtrl.scope.isScrolling

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
        if !result
          return false
        return (result?.rm_status=='recently sold'||result.rm_status=='not for sale') && result.close_date
        
      getPriceLabel: (status) ->
        if (status=='recently sold'||status=='not for sale')
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
        _isWithinBounds = (prop) =>
          pointBounds = GoogleService.GeoJsonTo.MultiPolygon.toBounds(prop.geom_polys_json)
          isVisible = @mapCtrl.gMap.getBounds().intersects(pointBounds)
          return unless isVisible
          prop

        unless @filterSummaryInBounds
          @filterSummaryInBounds = @mapCtrl.scope.layers.filterSummary.map (prop) =>
            if _isWithinBounds(prop)
              return prop
            return
          @filterSummaryInBounds = @filterSummaryInBounds.filter(Boolean) #remove nulls
          @mapCtrl.scope.resultsPotentialLength = @filterSummaryInBounds.length
        return unless @filterSummaryInBounds

        if not @mapCtrl.scope.results.length # only do this once (per map bound)
          @filterSummaryInBounds.forEach (summary) =>
            @mapCtrl.scope.results.push summary if @mapCtrl.scope.formatters.layer.isVisible(summary)

        @mapCtrl.scope.resultsLimit += amountToLoad
#        @bindResultsListEvents()

      click: (result) =>
        maybeFetchCb = (showDetails) =>
          #start getting more data
          if showDetails
            Properties.getPropertyDetail(@mapCtrl.mapState, result.rm_property_id, if result.rm_status then "detail" else "all")
            .then (data) =>
              angular.extend @mapCtrl.scope.selectedResult, data

          @mapCtrl.scope.Toggles.showDetails = showDetails

        #immediatley show something
        if @mapCtrl.scope.selectedResult != result
          @mapCtrl.scope.selectedResult = result
          #set the zoom back so it always is close to the property
          #immediatley turn off sat
          @mapCtrl.scope.streetViewPanorama.status = 'OK'
          @mapCtrl.scope.satMap.zoom = 20
          maybeFetchCb(true)
        else
          maybeFetchCb(false)
          @mapCtrl.scope.selectedResult = undefined

      mouseenter: (result) =>
        result.isMousedOver = true
        @mapCtrl.updateAllLayersByModel(result)

      mouseleave: (result) =>
        result.isMousedOver = undefined
        @mapCtrl.updateAllLayersByModel(result)

      clickSaveResultFromList: (result, eventOpts) =>
        event = eventOpts.$event
        if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)
#        alert("saved #{result.rm_property_id} #{event}")
        @mapCtrl.saveProperty(result).then =>
          @reset()

]
