###globals angular###
app = require '../app.coffee'


app.run ($templateCache) ->
  $templateCache.put 'drawMarker.tpl.html', require('../../html/views/templates/drawMarker.jade')()

app.config ($provide) ->
  $provide.decorator 'rmapsLeafletDrawDirectiveCtrlDefaultsService', ($delegate) ->

    angular.extend $delegate.drawContexts,
      sketchDraw: [
        'polyline'
        'rectangle'
        'circle'
        'polygon'
        {
          name: 'marker'
          template: 'drawMarker.tpl.html'
        }
        'text'
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
