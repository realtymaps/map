app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
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
      #controller:   "rmaps#{name.toInitCaps()}Ctrl"
      controller:   "rmaps#{name[0].toUpperCase()}#{name.substr(1)}Ctrl" # we can have CamelCase yay!
    _.extend(state, overrides)
    _.defaults(state, stateDefaults)

    if !state.template
      state.templateProvider = ($templateCache) ->
        templateName = if state.parent == 'main' or state.parent is null then "./views/#{name}.jade" else "./views/#{state.parent}/#{name}.jade"
        console.debug 'loading template:', name, 'from', templateName
        console.debug 'controller is:', state.controller
        #$templateCache.get "./views/#{name}.jade"
        $templateCache.get templateName

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
  buildState 'map', reloadOnSearch: false,
    params:
      project_id:
        value: null
        squash: true
      property_id:
        value: null
        squash: true

  buildState 'onBoardingPlan',
    template: require('../../html/views/onBoarding/onBoardingPlan.jade')
    sticky: false
    loginRequired: false
    permissionsRequired: false
  # buildState 'onBoardingPayment'
  # buildState 'onBoardingLocation'
  buildState 'snail'
  buildState 'user'
  buildState 'profiles'
  buildState 'history'
  buildState 'properties'
  buildState 'projects'
  buildState 'project'
  buildState 'projectClients', parent: 'project'
  buildState 'projectNotes', parent: 'project'
  buildState 'projectFavorites', parent: 'project'
  buildState 'projectNeighbourhoods', parent: 'project'
  buildState 'projectPins', parent: 'project'
  buildState 'neighbourhoods'
  buildState 'notes'
  buildState 'favorites'
  buildState 'sendEmailModal'
  buildState 'newEmail'

  buildState 'mail'
  buildState 'mailWizard'
  buildState 'selectTemplate', parent: 'mailWizard'
  buildState 'editTemplate', parent: 'mailWizard'

  buildState 'login', template: require('../../../common/html/login.jade'), sticky: false, loginRequired: false
  buildState 'logout', sticky: false, loginRequired: false
  buildState 'accessDenied', controller: null, sticky: false, loginRequired: false
  buildState 'authenticating', controller: null, sticky: false, loginRequired: false
  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null, sticky: false, loginRequired: false

  $urlRouterProvider.when '', frontendRoutes.index
