app = require '../app.coffee'

app.factory 'rmapsProperty', ->
  class Property
    constructor:(@rm_property_id, @isSaved = false, @isFavorite = false, @isHidden = false, @notes = undefined) ->
