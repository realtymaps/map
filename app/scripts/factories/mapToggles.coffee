app = require '../app.coffee'
StringToBoolean = require '../../../common/utils/util.stringToBoolean.coffee'

app.factory 'MapToggles'.ourNs(), [ ->

  (json) ->
    @showResults
    @showDetails = false
    @showFilters = false

    @showAddresses = true
    @showPrices = true

    @toggleAddresses = =>
      @showAddresses = !@showAddresses
    @togglePrices = ->
      @showPrices = !@showPrices

    if json?
      _.extend @, StringToBoolean.booleanify(json)
    @
]
