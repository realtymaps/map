app = require '../scripts/app.coffee'
templates = [
  {name: 'map-draw.tpl.html', tpl: require('jade!../../html/templates/map-draw.tpl.jade')}
]

#load all templates via webpack
#then load them into the angular $templateCache
app.run ['$templateCache', ($templateCache) ->
  templates.forEach (tpl) ->
    $templateCache.put tpl.name, tpl.tpl
]