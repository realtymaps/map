###global _:true###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

stateDefaults =
  sticky: true
  loginRequired: true

module.exports = app.config ($stateProvider, $stickyStateProvider, $urlRouterProvider,
rmapsOnBoardingOrderProvider, rmapsOnBoardingProOrderProvider) ->

  buildState = (name, overrides = {}) ->
    state =
      name:         name
      parent:       'main'
      url:          frontendRoutes[name],
      #controller:   "rmaps#{name.toInitCaps()}Ctrl"
      controller:   "rmaps#{name[0].toUpperCase()}#{name.substr(1)}Ctrl" # we can have CamelCase yay!
    _.extend(state, overrides)
    _.defaults(state, stateDefaults)

    if !state.template && !state.templateProvider
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

  buildState 'onBoarding',
    abstract: true
    url: frontendRoutes.onBoarding
    loginRequired: false
    permissionsRequired: false

  buildState 'onBoardingPlan',
    parent: 'onBoarding'
    loginRequired: false
    permissionsRequired: false
    showSteps: false

  rmapsOnBoardingOrderProvider.steps.forEach (boardingName) ->
    buildState boardingName,
      parent: 'onBoarding'
      url: '/' + (rmapsOnBoardingOrderProvider.getId(boardingName) + 1)
      loginRequired: false
      permissionsRequired: false
      showSteps: true

  rmapsOnBoardingProOrderProvider.steps.forEach (boardingName) ->
    buildState boardingName + 'Pro',
      parent: 'onBoarding'
      controller: "rmaps#{boardingName[0].toUpperCase()}#{boardingName.substr(1)}Ctrl"
      url: '/pro/' + (rmapsOnBoardingProOrderProvider.getId(boardingName) + 1)
      templateProvider: ($templateCache) ->
        $templateCache.get "./views/onBoarding/#{boardingName}.jade"
      loginRequired: false
      permissionsRequired: false
      showSteps: true

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
  buildState 'mailWizard',
    params: property_ids: null

  buildState 'selectTemplate', parent: 'mailWizard'
  buildState 'editTemplate', parent: 'mailWizard'
  buildState 'senderInfo', parent: 'mailWizard'

  buildState 'login', template: require('../../../common/html/login.jade'), sticky: false, loginRequired: false
  buildState 'logout', sticky: false, loginRequired: false
  buildState 'accessDenied', controller: null, sticky: false, loginRequired: false
  buildState 'authenticating', controller: null, sticky: false, loginRequired: false
  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null, sticky: false, loginRequired: false

  $urlRouterProvider.when '', frontendRoutes.index
