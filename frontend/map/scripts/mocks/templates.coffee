app = require '../app.coffee'

app.run ['$templateCache', ($templateCache) ->
  [
    {name: 'results-tray.tpl.html', tpl: require('../../html/includes/results-tray.jade')}
  ].forEach (tpl) ->
    $templateCache.put tpl.name, tpl.tpl
]