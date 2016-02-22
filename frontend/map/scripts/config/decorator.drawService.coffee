###globals angular###
app = require '../app.coffee'

app.config ($provide) ->
  $provide.decorator 'rmapsLeafletDrawDirectiveCtrlDefaults', ($delegate) ->

    angular.extend $delegate.drawContexts
      sketchDraw: [
        'polyline'
        'square'
        'circle'
        'polygon'
        'text'
        'redo'
        'undo'
        'trash'
      ]
