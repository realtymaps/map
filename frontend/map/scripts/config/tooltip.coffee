app = require '../app.coffee'

app.config ($tooltipProvider) ->
  $tooltipProvider.setTriggers
    'keyup': 'keydown'
