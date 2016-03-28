###globals _###
app = require '../app.coffee'

app.factory 'rmapsMapTogglesFactory', ($log) ->
  $log = $log.spawn 'map:rmapsMapTogglesFactory'

  class MapToggles
    @currentToggles: null

    constructor: (json) ->
      $log.debug 'Contruct Map Toggles from JSON:', json
      @constructor.currentToggles = @

      _locationCb = null
      @showResults = false
      @showDetails = false
      @showFilters = false
      @showSearch = false
      @isFetchingLocation = false
      @hasPreviousLocation = false

      @showAddresses = true
      @showPrices = true
      @showNeighbourhoodTap = false
      @showNotes = false
      @showMail = false
      @propertiesInShapes = false

      if json?
        _.extend @, json

      # Don't load any of the following from the database

      @isSketchMode = false
      @isNeighborhoodDraw = false
      @showOldToolbar = false

      @enableNoteTap = () =>
        @showNoteTap = true

      @enableNeighbourhoodTap = () =>
        @showNeighbourhoodTap = true

      @toggleNotes = () =>
        @showNotes = !@showNotes

      @toggleNoteTap = () =>
        @showNoteTap = !@showNoteTap

      @toggleMail = () =>
        @showMail = !@showMail

      @toggleAddresses = () =>
        @showAddresses = !@showAddresses

      @togglePrices = () =>
        @showPrices = !@showPrices

      @toggleDetails = () =>
        @showDetails = !@showDetails

      @toggleResults = () =>
        if @showDetails
          @showDetails = false
          @showResults = true
          return
        @showResults =  !@showResults

      @toggleFilters = () =>
        @showFilters = !@showFilters

      @setPropertiesInShapes = (bool) ->
        if bool != @propertiesInShapes
          @propertiesInShapes = bool

      @togglePropertiesInShapes = () ->
        return if @isSketchMode && @propertiesInShapes
        @setPropertiesInShapes !@propertiesInShapes

      @toggleIsSketchMode = () =>
        @isSketchMode = !@isSketchMode

      @toggleIsNeighborhoodDraw = () =>
        @isNeighborhoodDraw = !@isNeighborhoodDraw

      @getHideAnyDraw = () =>
        @isSketchMode or @isNeighborhoodDraw

      @toggleSearch = (val) =>
        if val?
          @showSearch = val
        else
          @showSearch = !@showSearch

        if @showSearch
          # let angular have a chance to attach the input box...
          document.getElementById('places-search-input')?.focus()

      @setLocationCb = (cb) ->
        _locationCb = cb

      @toggleLocation = () =>
        @isFetchingLocation = true
        navigator.geolocation.getCurrentPosition (location) =>
          @isFetchingLocation = false
          _locationCb(location)

      @togglePreviousLocation = ->
        _locationCb()

      @setLocation = (location) ->
        _locationCb?(location)

      @
