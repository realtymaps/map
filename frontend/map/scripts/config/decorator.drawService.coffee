###globals angular###
app = require '../app.coffee'

app.config ($provide) ->
  $provide.decorator 'rmapsLeafletDrawDirectiveCtrlDefaultsService', ($delegate) ->

    angular.extend $delegate.drawContexts,
      sketchDraw: [
        'polyline'
        'rectangle'
        'circle'
        'polygon'
        'edit'
        'trash'
      ]
      area: [
        'rectangle'
        'circle'
        'polygon'
        'edit'
        'trash'
      ]

    $delegate
