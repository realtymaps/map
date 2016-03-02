###globals _###
app = require '../app.coffee'

app.factory 'rmapsMapTogglesFactory', () ->

  (json) ->
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
    @propertiesInShapes = false
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

    @setPropetiesInShapes = (bool) ->
      if bool != @propertiesInShapes
        @propertiesInShapes = bool

    @togglePropertiesInShapes = () ->
      return if @isSketchMode && @propertiesInShapes
      @setPropetiesInShapes !@propertiesInShapes

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

    if json?
      _.extend @, _.mapValues json, (val) ->
        return val == 'true'
    @
