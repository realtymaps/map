app = require '../app.coffee'

app.run ($templateCache) ->
  [
    {name: 'results-tray.tpl.html', tpl: require('../../html/includes/map/_properties.jade')}
  ].forEach (tpl) ->
    $templateCache.put tpl.name, tpl.tpl()