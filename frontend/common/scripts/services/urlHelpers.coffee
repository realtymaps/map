frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
mod = require '../module.coffee'

mod.service 'rmapsUrlHelpersService', ($location) ->

  getRoutes = () ->
    return if ///^\/admin///.test($location.path()) then adminRoutes else frontendRoutes

  getRoutes: getRoutes
