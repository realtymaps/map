mod = require '../module.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

#https://code.angularjs.org/1.5.5/docs/guide/production
mod.config ($provide, $compileProvider) ->
  #NOTE THIS IS NOT REALLY WORKING as the decorator hack to get around angular.cofig limitations is not working
  #https://realtymaps.atlassian.net/browse/MAPD-1091
  #use decorator to access to $http at config time (semi-hack)
  #this then allows us to set the $compileProvider.debugInfoEnabled
  $provide.decorator '$http', ($delegate) ->

    $delegate.get(backendRoutes.config.safeConfig, cache: true)
    .then ({data}) ->
      #WE need to compile this into our production build vial gulp
      $compileProvider.debugInfoEnabled data.ANGULAR.DO_COMPILE_DEBUG

    $delegate
