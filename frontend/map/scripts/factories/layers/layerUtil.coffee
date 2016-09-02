stampit = require 'stampit'
app = require '../../app.coffee'

app.factory 'rmapsLayerUtil', () ->
  stampit.methods
    isEmptyData: () ->
      !@data? or typeof @data == 'string'
