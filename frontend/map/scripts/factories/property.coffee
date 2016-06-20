app = require '../app.coffee'

app.factory 'rmapsPropertyFactory', ->
  class Property
    constructor:(@rm_property_id, @isFavorite = false, @notes = undefined) ->
