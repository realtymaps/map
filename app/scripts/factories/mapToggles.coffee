app = require '../app.coffee'
StringToBoolean = require '../../../common/utils/util.stringToBoolean.coffee'

app.factory 'MapToggles'.ourNs(), [ ->

  (json) ->
    @showResults = false
    @showDetails = false
    @showFilters = false

    @showAddresses = true
    @showPrices = true

    @toggleAddresses = =>
      @showAddresses = !@showAddresses

    @togglePrices = =>
      @showPrices = !@showPrices

    @toggleDetails = =>
      @showDetails = !@showDetails

    @toggleResults = =>
      if @showDetails
        @showDetails = false
        @showResults = true unless @showResults #edge case (detail open from marker click w/ no results), if show leave it
        return
      @showResults =  !@showResults


    if json?
      _.extend @, StringToBoolean.booleanify(json)
    @
]
