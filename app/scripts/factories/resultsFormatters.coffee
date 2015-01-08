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

    resultEvents = ['dblclick', 'mouseover', 'mouseleave']

    class ResultsFormatter
      constructor: (@mapCtrl) ->
        @mapCtrl.scope.results = []
        @mapCtrl.scope.resultsPotentialLength = undefined
        @mapCtrl.scope.resultsAscending = false
        @setResultsPredicate('price')
        @lastSummaryIndex = 0
        @origLen = 0

        @mapCtrl.scope.$watch 'layers.filterSummary', (newVal, oldVal) =>
          return if newVal == oldVal
          @lastSummaryIndex = 0
          @mapCtrl.scope.results = []
          @loadMore()

      order: =>
        @filterSummarySorted = _orderBy(
          @mapCtrl.scope.layers.filterSummary, @mapCtrl.scope.resultsPredicate, @mapCtrl.scope.resultsAscending)

      reset:  ->
        @mapCtrl.scope.results = []
        @lastSummaryIndex = 0
        @mapCtrl.scope.resultsPotentialLength = undefined
        @order()
        @loadMore()

      setResultsPredicate: (predicate) =>
        @mapCtrl.scope.resultsPredicate = predicate
        @order()

      getSorting: =>
        if @mapCtrl.scope.resultsAscending
          "fa fa-chevron-circle-down"
        else
          "fa fa-chevron-circle-up"

      getActiveSort: (toMatchSortStr) =>
        if toMatchSortStr == @mapCtrl.scope.resultsPredicate then 'active-sort' else ''

      invertSorting: =>
        @mapCtrl.scope.resultsAscending = !@mapCtrl.scope.resultsAscending

      getCurbsideImage: (result) ->
        return 'http://placehold.it/100x75' unless result
        lonLat = result.geom_point_json.coordinates
        "http://cbk0.google.com/cbk?output=thumbnail&w=100&h=75&ll=#{lonLat[1]},#{lonLat[0]}&thumb=1"

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
        if @loader
          $timeout.cancel @loader
        @loader = $timeout @throttledLoadMore

      throttledLoadMore: (amountToLoad = 10, loadedCtr = 0) =>
        _isWithinBounds = (prop) =>
          pointBounds = GeoJsonToGoogle.MultiPolygon.toBounds(prop.geom_polys_json)
          isVisible = @mapCtrl.gMap.getBounds().intersects(pointBounds)
          return unless isVisible
          prop

        unless @mapCtrl.scope.resultsPotentialLength
          ctr = 0
          @mapCtrl.scope.layers.filterSummary.forEach (prop) =>
            ctr += 1 if _isWithinBounds(prop)
          @mapCtrl.scope.resultsPotentialLength = ctr

        return if not @mapCtrl.scope.layers.filterSummary.length
        for i in [0..amountToLoad] by 1
          if @lastSummaryIndex > @mapCtrl.scope.layers.filterSummary.length - 1
            break
          prop = @mapCtrl.scope.layers.filterSummary[@lastSummaryIndex]

          #this is done since we aggressively grab items outside what is visible
          #this way the results align with what can be seen
          if prop and _isWithinBounds(prop)
            @mapCtrl.scope.results.push(prop)
            loadedCtr += 1

          @lastSummaryIndex += 1

        if loadedCtr < amountToLoad and @lastSummaryIndex < @mapCtrl.scope.layers.filterSummary.length
          @throttledLoadMore(amountToLoad, loadedCtr)

        if @oldEventsPromise?
          $timeout.cancel @oldEventsPromise
        @oldEventsPromise = $timeout ->
          #finally , hook mouseover / mouseleave manually for performance
          #use ng-init to pass in id name and class names of properties to keep loose coupling
          resultEvents.forEach (eventName) =>
            angular.element(document.getElementsByClassName('result-property ng-scope'))
            .unbind(eventName)
            .bind eventName, (event) =>
              @[eventName](angular.element(event.srcElement).scope().result)

      dblclick: (result) =>
        @mapCtrl.selectedResult = result

      mouseover: (result) =>
        #not updating the polygon cause I think we really need access to its childModels / plurals
        #notw add that to control on uigmap
        result.isMousedOver = true

      mouseleave: (result) =>
        result.isMousedOver = undefined
]
