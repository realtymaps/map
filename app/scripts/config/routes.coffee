app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'

#if this configuration gets much larger consider breaking this into a config folder

module.exports = app.config [ '$routeProvider', ($routeProvider) ->
  $routeProvider

  .when frontendRoutes.map,
    template: require('../../html/views/map.jade')
    controller: 'MapCtrl'.ourNs()
    loginRequired: true
    
  .when frontendRoutes.users,
    template: require('../../html/views/users.html')
    controller: 'UserCtrl'.ourNs()

  .when frontendRoutes.login,
    template: require('../../html/views/login.jade')
    controller: 'LoginCtrl'.ourNs()

  .when frontendRoutes.logout,
    template: require('../../html/views/logout.jade')
    controller: 'LogoutCtrl'.ourNs()
    
  .when frontendRoutes.index,
    template: require('../../html/views/main.html')
    controller: 'MainCtrl'.ourNs()
    
  .when frontendRoutes.serverError,   template: require('../../html/views/500.html')
  .when frontendRoutes.notFound,      template: require('../../html/views/404.html')
  .when frontendRoutes.accessDenied,  template: require('../../html/views/401.html')
  
  # we probably want something separate from the 404 view for unknown FE states, but this will do for now
  .otherwise template: require('../../html/views/404.html')
]
