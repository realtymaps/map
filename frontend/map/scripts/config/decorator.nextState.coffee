app = require '../app.coffee'

app.config ($provide) ->
  $provide.decorator '$state', ($delegate, $rootScope) ->
    $rootScope.$on '$stateChangeStart', (event, state, params) ->
      $delegate.toState = state
      $delegate.toParams = params

    return $delegate
