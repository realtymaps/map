app = require '../app.coffee'

app.run ($rootScope, $anchorScroll) ->
  $rootScope.$on "$stateChangeSuccess", (event, state, params) ->
    if params?.scrollTo
      $anchorScroll(params.scrollTo)
