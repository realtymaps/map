app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
loginTemplate = require '../../../common/html/login.jade'

# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

stateDefaults =
  sticky: true
  loginRequired: true

module.exports = app.config ($stateProvider, $stickyStateProvider, $urlRouterProvider) ->

  buildState = (name, overrides = {}) ->
    state =
      name:         name
      parent:       'main'
      url:          frontendRoutes[name],
      controller:   "rmaps#{name.toInitCaps()}Ctrl"
    _.extend(state, overrides)
    _.defaults(state, stateDefaults)

    if !state.template
      state.templateProvider = ($templateCache) ->
        console.debug 'loading template:', name
        $templateCache.get "./views/#{name}.jade"

    if state.parent
      state.views = {}
      state.views["#{name}@#{state.parent}"] =
        templateProvider: state.templateProvider
        template: state.template
        controller: state.controller
      delete state.template
      delete state.controller
    $stateProvider.state(state)
    state


  buildState 'main', parent: null, url: frontendRoutes.index, loginRequired: false
  buildState 'map'
  buildState 'snail'
  buildState 'user'
  buildState 'profiles'
  buildState 'history'
  buildState 'mail'
  buildState 'properties'
  buildState 'projects'
  buildState 'neighbourhoods'
  buildState 'notes'
  buildState 'favorites'
  buildState 'addProjects'
  buildState 'sendEmailModal'
  buildState 'newEmail'

  buildState 'login', template: loginTemplate, sticky: false, loginRequired: false
  buildState 'logout', sticky: false, loginRequired: false
  buildState 'accessDenied', controller: null, sticky: false, loginRequired: false
  buildState 'authenticating', controller: null, sticky: false, loginRequired: false
  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null, sticky: false, loginRequired: false

  $urlRouterProvider.when '', frontendRoutes.index
