app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
loginTemplate = require("../../../common/html/login.jade")

# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

module.exports = app.config ($stateProvider, $stickyStateProvider, $urlRouterProvider) ->

  buildState = (name, overrides = {}) ->
    state =
      name:         name
      parent:       'main'
      url:          frontendRoutes[name],
      controller:   "rmaps#{name.toInitCaps()}Ctrl"
      # template:     require "../../html/views/#{name}.jade"
    _.extend(state, overrides)

    if !state.template
        state.template = require "../../html/views/#{name}.jade"

    if state.parent
      state.views = {}
      state.views["#{name}@#{state.parent}"] =
        template: state.template
        controller: state.controller
      delete state.template
      delete state.controller
    $stateProvider.state(state)
    state


  buildState 'main', parent: null, url: frontendRoutes.index, sticky: true
  buildState 'map', sticky:true, loginRequired:true
  buildState 'login', template: loginTemplate
  buildState 'logout'
  buildState 'accessDenied', controller: null
  buildState 'authenticating', controller: null
  buildState 'snail', sticky: true
  buildState 'user', sticky:true, loginRequired:true
  buildState 'profiles', sticky:true, loginRequired:true
  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null

  $urlRouterProvider.when '', frontendRoutes.index
