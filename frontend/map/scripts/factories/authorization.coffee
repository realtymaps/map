app = require '../app.coffee'
authorization = require '../../../common/scripts/factories/authorization.coffee'
module.exports = app.factory 'rmapsauthorization', authorization

app.run ($rootScope, rmapsauthorization) ->
  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    rmapsauthorization.authorize(toState, toParams, fromState, fromParams)
    return
