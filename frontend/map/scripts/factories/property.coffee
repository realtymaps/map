app = require '../app.coffee'

app.factory 'rmapsProperty', ->
  class Property
    constructor:(@rm_property_id, @isSaved, @isHidden, @notes) ->
