app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.factory 'ResultsFormatter'.ourNs(), ['Logger'.ourNs(), 'ParcelEnums'.ourNs(), '$timeout',
  ($log, ParcelEnums, $timeout) ->

    _forSaleClass = {}
    _forSaleClass[ParcelEnums.status.sold] = 'sold'
    _forSaleClass[ParcelEnums.status.pending] = 'forSale'
    _forSaleClass[ParcelEnums.status.forSale] = 'forSale'
    _forSaleClass['saved'] = 'saved'
    _forSaleClass['default'] = ''

    class ResultsFormatter
      constructor: (@scope) ->
        @scope.results = []
        @lastSummaryIndex = 0
        @origLen = 0
        @scope.$watch 'layers.filterSummary', (newVal, oldVal) =>
          return if newVal == oldVal
          @lastSummaryIndex = 0
          @scope.results = []
          @loadMore()

      getCurbsideImage: (result) ->
        return 'http://placehold.it/100x75' unless result
        lonLat = result.geom_point_json.coordinates
        "http://cbk0.google.com/cbk?output=thumbnail&w=100&h=75&ll=#{lonLat[1]},#{lonLat[0]}&thumb=1"

      getForSaleClass: (result) ->
        return unless result
        _forSaleClass[result.rm_status] or _forSaleClass['default']

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

      throttledLoadMore: (amountToLoad = 10) =>
        return if not @scope.layers.filterSummary.length

        for i in [0..amountToLoad] by 1
          if @lastSummaryIndex > @scope.layers.filterSummary.length - 1
            break
          prop = @scope.layers.filterSummary[@lastSummaryIndex]
          @scope.results.push(prop) if prop
          @lastSummaryIndex += 1
]
#mls.rm_status
#parcel.street_address_num