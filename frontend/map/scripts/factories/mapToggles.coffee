_ = require 'lodash'
app = require '../app.coffee'

app.factory 'rmapsMapTogglesFactory', ($log, $rootScope, rmapsEventConstants) ->
  $log = $log.spawn 'map:rmapsMapTogglesFactory'

  _fireLocationChange = (position) ->
    $rootScope.$emit rmapsEventConstants.map.locationChange, position

  ### MapToggles:
    TODO: We should consider changing the name of this to something revolving around user state as almost all UI switch like
    settings are saved here.
  ###
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
      @useSatellite = false

      @showAddresses = true
      @showPrices = true
      @showNotes = false
      @showMail = false
      @propertiesInShapes = false
      @isTacks =
        area: false
        quickStats: false
        sketch: false

      if json?
        _.extend @, json

      # Don't load any of the following from the database

      @isSketchMode = false
      @isAreaDraw = false
      @isStatsDraw = false
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

      @getTack = (name) =>
        @isTacks[name]

      @toggleIsAreaDraw = ({stats} = {}) =>
        @isAreaDraw = !@isAreaDraw
        if @isAreaDraw && stats
          @isStatsDraw = true
          @isTacks.quickStats = true
        else
          @isStatsDraw = false

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

      @togglePreviousLocation = ->
        _fireLocationChange()

      @toggleTack = (name) =>
        $log.debug => "toggling isTacks #{name} old: #{@isTacks[name]} new: #{!@isTacks[name]}"
        @isTacks[name] = !@isTacks[name]

      @setLocation = _fireLocationChange

      @
