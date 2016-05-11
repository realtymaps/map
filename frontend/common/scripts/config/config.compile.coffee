mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

#https://code.angularjs.org/1.5.5/docs/guide/production
mod.config ($provide, $compileProvider) ->
  #use decorator to access to $http at config time (semi-hack)
  #this then allows us to set the $compileProvider.debugInfoEnabled
  $provide.decorator '$http', ($delegate) ->

    $delegate.get(backendRoutes.config.safeConfig, cache: true)
    .then ({data}) ->
      isDebugLike = data.envLevel != 'production' && data != 'staging'

      $compileProvider.debugInfoEnabled isDebugLike

    $delegate
