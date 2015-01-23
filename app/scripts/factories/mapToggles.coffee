app = require '../app.coffee'
StringToBoolean = require '../../../common/utils/util.stringToBoolean.coffee'

app.factory 'MapToggles'.ourNs(), [ '$rootScope', ($rootScope) ->

  (json) ->
    @showResults = false
    @showDetails = false
    @showFilters = false
    @showSearch = false

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
        @showResults = true
        return
      @showResults =  !@showResults

    @toggleSearch = (val) =>
      if val?
        @showSearch = val
      else
        @showSearch = !@showSearch
        
      if @showSearch
        # let angular have a chance to attach the input box...
        document.getElementById('places-search-input')?.focus()

    if json?
      _.extend @, StringToBoolean.booleanify(json)
    @
]
