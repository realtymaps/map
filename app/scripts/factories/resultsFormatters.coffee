app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.factory 'ResultsFormatter'.ourNs(), ['Logger'.ourNs(), 'ParcelEnums'.ourNs(), '$timeout',
  ($log, ParcelEnums, $timeout) ->

    _forSaleClass = {}
    _forSaleClass[ParcelEnums.status.sold] = 'sold'
    _forSaleClass[ParcelEnums.status.pending] = 'pending'
    _forSaleClass[ParcelEnums.status.forSale] = 'forsale'
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

        @scope.resultsGridOpts =
          rowHeight: 75
#          showFooter: false
          data: 'results'
          rowTemplate: """
            <div id='l-el{{row.getProperty(\"rm_property_id\")}}' class='card animated slide-down' ng-click='showDetails = !showDetails'>
              <div ng-repeat="col in renderedColumns" ng-class="col.colIndex()" class="ngCell ">
                <div class="ngVerticalBar" ng-style="{height: rowHeight}" ng-class="{ ngVerticalBarVisible: !$last }">
                </div>
                <div ng-cell></div>
              </div>
            </div>
            """
          columnDefs: [
            {
              field:'address', displayName: 'Address', cellTemplate: '<div class="address">{{row.entity[col.field]}}</div>'
              width:110
            }
            {
              field: 'photo', displayName: 'Photo',
              cellTemplate: '<div class="photo"><img ng-src="{{row.entity[col.field]}}"></div>'
              width: 100
            }
            {field: 'bedrooms', displayName: 'Beds', width:50}
            {field: 'baths_total', displayName: 'Baths', width:50}
            {field: 'finished_sqft', displayName: 'Sq Ft', width:50}
            {field: 'year_built', displayName: 'Year', width:50}
            {
              field: 'price', displayName: 'Price',
              cellTemplate: '<div class="price">{{row.entity[col.field]}}<div class="property-status"></div></div>'
            }
          ]

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
          prop.address = prop.street_address_num + " " + prop.street_address_name
          prop.price = @getPrice prop.price
          prop.photo = @getCurbsideImage prop
          ['bedrooms','baths_total', 'finished_sqft', 'year_built'].forEach (field) =>
            prop[field] = @orNa prop[field]
          prop.price = @getPrice prop.price
          @scope.results.push(prop) if prop
          @lastSummaryIndex += 1
]
#mls.rm_status
#parcel.street_address_num
