app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'

# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

module.exports = app.config [ '$stateProvider', '$stickyStateProvider', '$urlRouterProvider', ($stateProvider, $stickyStateProvider, $urlRouterProvider) ->

  buildState = (parent, name, overrides = {}) ->
    state = 
      name:         name
      parent:       parent
      url:          frontendRoutes[name],
      template:     require("../../html/views/#{name}.jade")
      controller:   "#{name[0].toUpperCase()}#{name.substr(1)}Ctrl".ourNs()
    _.extend(state, overrides)
    if parent
      state.views = {}
      state.views["#{name}@#{parent}"] =
        template: state.template
        controller: state.controller
      delete state.template
      delete state.controller
    $stateProvider.state(state)
  
  
  buildState null, 'main', url: frontendRoutes.index, sticky: true
  buildState 'main', 'map', sticky:true, loginRequired:true
  buildState 'main', 'login'
  buildState 'main', 'logout'
  buildState 'main', 'accessDenied', controller: null
  buildState 'main', 'pageNotFound', controller: null

  $urlRouterProvider.when '', frontendRoutes.index
]
