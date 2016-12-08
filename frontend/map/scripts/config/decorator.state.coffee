app = require '../app.coffee'
permissionUtil = require '../../../../common/utils/permissions.coffee'

app.config ($provide, $stateProvider) ->

  #HOLY SHIT THIS was hard to figure out
  #extending the state object (FOR ALL) is a pain in the ass
  $stateProvider.decorator 'isPermissionRequired', (state, parent) ->
    state.self.isPermissionRequired = (toMatch) ->
      permissionUtil.isPermissionRequired(toMatch, @permissionsRequired)


  $provide.decorator '$state', ($delegate, $rootScope) ->
    $rootScope.$on '$stateChangeStart', (event, state, params) ->
      $delegate.toState = state
      $delegate.toParams = params

    $delegate.isPermissionRequired = (state, toMatch) ->
      state.isPermissionRequired(toMatch)

    return $delegate
