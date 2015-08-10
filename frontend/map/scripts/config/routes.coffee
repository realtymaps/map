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
    _.extend(state, overrides)

    if !state.template
        state.templateProvider = ($templateCache) ->
          console.debug 'loading template:', name
          $templateCache.get "./views/#{name}.jade"

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
  buildState 'snail', sticky: true, loginRequired:true
  buildState 'user', sticky:true, loginRequired:true
  buildState 'profiles', sticky:true, loginRequired:true
  buildState 'history', sticky:true, loginRequired:true
  buildState 'mail', sticky:true, loginRequired:true
  buildState 'properties', sticky:true, loginRequired:true
  buildState 'projects', sticky:true, loginRequired:true
  buildState 'neighbourhoods', sticky:true, loginRequired:true
  buildState 'notes', sticky:true, loginRequired:true
  buildState 'favorites', sticky:true, loginRequired:true
  buildState 'addProjects', sticky:true, loginRequired:true
  buildState 'sendEmailModal', sticky:true, loginRequired:true
  buildState 'newEmail', sticky:true, loginRequired:true

  buildState 'login', template: loginTemplate
  buildState 'logout'
  buildState 'accessDenied', controller: null
  buildState 'authenticating', controller: null
  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null

  $urlRouterProvider.when '', frontendRoutes.index
