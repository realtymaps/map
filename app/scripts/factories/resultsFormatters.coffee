app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.factory 'ResultsFormatter'.ourNs(), ['$timeout', 'Logger'.ourNs(), 'ParcelEnums'.ourNs(), 'GeoJsonToGoogle'.ourNs(),
  ($timeout, $log, ParcelEnums, GeoJsonToGoogle) ->

    _forSaleClass = {}
    _forSaleClass[ParcelEnums.status.sold] = 'sold'
    _forSaleClass[ParcelEnums.status.pending] = 'pending'
    _forSaleClass[ParcelEnums.status.forSale] = 'forsale'
    _forSaleClass['saved'] = 'saved'
    _forSaleClass['default'] = ''

    class ResultsFormatter
      constructor: (@mapCtrl) ->
        @mapCtrl.scope.results = []
        @mapCtrl.scope.resultsPotentialLength = undefined
        @mapCtrl.scope.resultsAscending = false
        @mapCtrl.scope.resultsPredicate = 'price'
        @lastSummaryIndex = 0
        @origLen = 0

        @mapCtrl.scope.$watch 'layers.filterSummary', (newVal, oldVal) =>
          return if newVal == oldVal
          @lastSummaryIndex = 0
          @mapCtrl.scope.results = []
          @loadMore()

      reset: ->
        @mapCtrl.scope.results = []
        @lastSummaryIndex = 0
        @mapCtrl.scope.resultsPotentialLength = undefined
        @loadMore()

      setResultsPredicate: (predicate) =>
        @mapCtrl.scope.resultsPredicate = predicate

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
          @loader.finally @throttledLoadMore
        else
          @loader = $timeout @throttledLoadMore, 0

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
]