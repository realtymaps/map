app = require '../app.coffee'

app.config ($uibTooltipProvider) ->
  $uibTooltipProvider.setTriggers
    'keyup': 'keydown'
