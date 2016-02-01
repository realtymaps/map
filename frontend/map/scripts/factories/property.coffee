app = require '../app.coffee'

app.factory 'rmapsPropertyFactory', ->
  class Property
    constructor:(@rm_property_id, @isSaved = false, @isFavorite = false, @isHidden = false, @notes = undefined) ->
