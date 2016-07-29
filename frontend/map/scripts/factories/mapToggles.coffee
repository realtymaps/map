###globals _###
app = require '../app.coffee'

app.factory 'rmapsMapTogglesFactory', ($log, $rootScope, rmapsEventConstants) ->
  $log = $log.spawn 'map:rmapsMapTogglesFactory'

  _fireLocationChange = (position) ->
    $rootScope.$emit rmapsEventConstants.map.locationChange, position

  class MapToggles
    @currentToggles: null

    constructor: (json) ->
      $log.debug 'Contruct Map Toggles from JSON:', json
      @constructor.currentToggles = @

      @showResults = false
      @showDetails = false
      @showFilters = false
      @showSearch = false
      @isFetchingLocation = false
      @hasPreviousLocation = false

      @showAddresses = true
      @showPrices = true
      @showNotes = false
      @showMail = false
      @propertiesInShapes = false

      if json?
        _.extend @, json

      # Don't load any of the following from the database

      @isSketchMode = false
      @isAreaDraw = false
      @showOldToolbar = false

      @showAreaTap = false
      @showNoteTap = false

      @enableNoteTap = () =>
        @showNoteTap = true

      @enableAreaTap = () =>
        @showAreaTap = true

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

      @toggleIsAreaDraw = () =>
        @isAreaDraw = !@isAreaDraw

      @getHideAnyDraw = () =>
        @isSketchMode or @isAreaDraw

      @toggleSearch = (val) =>
        if val?
          @showSearch = val
        else
          @showSearch = !@showSearch

        if @showSearch
          # let angular have a chance to attach the input box...
          document.getElementById('places-search-input')?.focus()


      @toggleLocation = () =>
        @isFetchingLocation = true
        navigator.geolocation.getCurrentPosition (location) =>
          location.isMyLocation = true
          @isFetchingLocation = false
          _fireLocationChange(location)
        , (->), timeout:10000

      @togglePreviousLocation = ->
        _fireLocationChange()

      @setLocation = _fireLocationChange

      @
