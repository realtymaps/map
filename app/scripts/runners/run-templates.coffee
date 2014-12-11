app = require '../app.coffee'

templates = [
  {name: 'map-draw.tpl.html', tpl: require('../../html/views/templates/map-draw.tpl.jade')}
  {name: 'map-debug.tpl.html', tpl: require('../../html/views/templates/map-debug.tpl.jade')}
]

#load all templates via webpack
#then load them into the angular $templateCache
app.run ['$templateCache', ($templateCache) ->
  templates.forEach (tpl) ->
    $templateCache.put tpl.name, tpl.tpl
]