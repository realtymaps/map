app = require '../app.coffee'

app.factory 'Property'.ourNs(), [ ->
  class Property
    constructor:(@rm_property_id, @isSaved, @isHidden, @notes) ->
]
