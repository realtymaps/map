app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.factory 'ResultsFormatter'.ourNs(), ['$timeout', '$filter', 'Logger'.ourNs(), 'ParcelEnums'.ourNs(), 'GeoJsonToGoogle'.ourNs(),
  ($timeout, $filter, $log, ParcelEnums, GeoJsonToGoogle) ->
    _orderBy = $filter('orderBy')

    _forSaleClass = {}
    _forSaleClass[ParcelEnums.status.sold] = 'sold'
    _forSaleClass[ParcelEnums.status.pending] = 'pending'
    _forSaleClass[ParcelEnums.status.forSale] = 'forsale'
    _forSaleClass['saved'] = 'saved'
    _forSaleClass['default'] = ''

    resultEvents = ['click','dblclick', 'mouseover', 'mouseleave']

    class ResultsFormatter
      constructor: (@mapCtrl) ->
        @mapCtrl.scope.resultsLimit = 10
        @mapCtrl.scope.results = []
        @mapCtrl.scope.resultsPotentialLength = undefined
        @mapCtrl.scope.resultsAscending = false
        @setResultsPredicate('price')
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

      order: =>
        @filterSummarySorted = _orderBy(
          @mapCtrl.scope.layers.filterSummary, @mapCtrl.scope.resultsPredicate, @mapCtrl.scope.resultsAscending)

      reset:  ->
        @mapCtrl.scope.resultsLimit = 10
        @mapCtrl.scope.results = []
        @lastSummaryIndex = 0
        @mapCtrl.scope.resultsPotentialLength = undefined
        @filterSummaryInBounds = undefined
        @order()
        @loadMore()

      invertSorting: =>
        @mapCtrl.scope.resultsAscending = !@mapCtrl.scope.resultsAscending

      setResultsPredicate: (predicate) =>
        @mapCtrl.scope.resultsPredicate = predicate
        @order()

      getSorting: =>
        if @mapCtrl.scope.resultsAscending
          "fa fa-chevron-circle-down"
        else
          "fa fa-chevron-circle-up"

      getCityStateZip:(result, prependProp = '') ->
        return if not @mapCtrl.scope.Toggles.showResults or not result
        vals = ['city','state','zip'].map (l) =>
          @orNa result[prependProp + l]
        # $log.debug vals
        "#{vals[0]}, #{vals[1]} #{vals[2]}"

      getActiveSort: (toMatchSortStr) =>
        if toMatchSortStr == @mapCtrl.scope.resultsPredicate then 'active-sort' else ''

      getCurbsideImage: (result) ->
        return 'http://placehold.it/100x75' unless result
        lonLat = result.geom_point_json.coordinates
        "http://cbk0.google.com/cbk?output=thumbnail&w=100&h=75&ll=#{lonLat[1]},#{lonLat[0]}&thumb=1"

      getStreetView: (width, height, fov = '90', heading = '', pitch = '10', sensor = 'false') ->
        # https://developers.google.com/maps/documentation/javascript/reference#StreetViewPanorama
        # heading is better left as undefined as google figures out the best heading based on the lat lon target
        # we might want to consider going through the api which will gives us URL
        selectedResult = @mapCtrl.scope.selectedResult
        if heading
          heading = "&heading=#{heading}"
        return unless selectedResult
        lonLat = selectedResult.geom_point_json.coordinates
        "http://maps.googleapis.com/maps/api/streetview?size=#{width}x#{height}" +
        "&location=#{lonLat[1]},#{lonLat[0]}" +
        "&fov=#{fov}#{heading}&pitch=#{pitch}&sensor=#{sensor}"

      getForSaleClass: (result) ->
        return unless result
#        $log.debug "result: #{JSON.stringify(result)}"
        soldClass = _forSaleClass['saved'] if result.savedDetails?.isSaved
        soldClass or _forSaleClass[result.rm_status] or _forSaleClass['default']

      getPrice: (price) ->
        numeral(price).format('$0,0.00')

      orNa: (val) ->
        String.orNA val

      loadMore: =>
        #debugging
        return unless @mapCtrl.scope.Toggles.showResults
        @postRepeat.lastTime = new Date() if @postRepeat
        #end debugging
        if @loader
          $timeout.cancel @loader
        @loader = $timeout @throttledLoadMore

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
          pointBounds = GeoJsonToGoogle.MultiPolygon.toBounds(prop.geom_polys_json)
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
            @mapCtrl.scope.results.push summary

        @mapCtrl.scope.resultsLimit += amountToLoad


        # if @oldEventsPromise?
        #   $timeout.cancel @oldEventsPromise
        # @oldEventsPromise = $timeout =>
        _.defer =>
          #finally , hook mouseover / mouseleave manually for performance
          #use ng-init to pass in id name and class names of properties to keep loose coupling
          #TODO use a performant directive
          resultEvents.forEach (eventName) =>
            angular.element(document.getElementsByClassName(@mapCtrl.scope.resultClass))
            .unbind(eventName)
            .bind eventName, (event) =>
              @[eventName](angular.element(event.target or event.srcElement).scope().result)
              # if event.stopPropagation then event.stopPropagation() else (event.cancelBubble=true)

      click: (result) =>
        @mapCtrl.scope.selectedResult = result
        @mapCtrl.scope.showDetails = true

      dblclick: (result) =>

      mouseover: (result) =>
        #not updating the polygon cause I think we really need access to its childModels / plurals
        #notw add that to control on uigmap
        result.isMousedOver = true

      mouseleave: (result) =>
        result.isMousedOver = undefined
]
