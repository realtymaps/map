###global _:true###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

stateDefaults =
  sticky: false
  loginRequired: true

module.exports = app.config ($stateProvider, $stickyStateProvider, $urlRouterProvider,
rmapsOnboardingOrderServiceProvider, rmapsOnboardingProOrderServiceProvider) ->

  baseState = (name, overrides = {}) ->
    state =
      name:         name
      parent:       'main'
      url:          frontendRoutes[name],
      #controller:   "rmaps#{name.toInitCaps()}Ctrl"
      controller:   "rmaps#{name[0].toUpperCase()}#{name.substr(1)}Ctrl" # we can have CamelCase yay!
    _.extend(state, overrides)
    _.defaults(state, stateDefaults)

    return state

  appendTemplateProvider = (name, state) ->
    if !state.template && !state.templateProvider
      state.templateProvider = ($templateCache) ->
        templateName = if state.parent == 'main' or state.parent is null then "./views/#{name}.jade" else "./views/#{state.parent}/#{name}.jade"
        console.log "State #{name} using template #{templateName}"
        $templateCache.get templateName

  createView = (name, state, viewName = name) ->
    state.views = {}
    state.views["#{viewName}@#{state.parent}"] =
      templateProvider: state.templateProvider
      template: state.template
      controller: state.controller
    delete state.template
    delete state.controller

  buildMapState = (overrides = {}) ->
    name = 'map'
    state = baseState name, overrides
    appendTemplateProvider name, state
    createView name, state, 'main-map'

    # Set the page type
    state.pageType = 'map'

    $stateProvider.state(state)
    state

  buildModalState = (name, overrides = {}) ->
    state = baseState name, overrides
    appendTemplateProvider name, state
    createView name, state, 'main-modal'

    # Set the page type
    state.pageType = 'modal'

    $stateProvider.state(state)
    state

  buildState = (name, overrides = {}) ->
    state = baseState name, overrides
    appendTemplateProvider name, state

    if state.parent
      createView name, state, 'main-page'

    # Set the page type
    state.pageType = 'page'

    $stateProvider.state(state)
    state

  buildChildState = (name, parent, overrides = {}) ->
    state = baseState name, overrides
    state.parent = parent

    appendTemplateProvider name, state

    # Set the page type
#    state.pageType = 'child'

    console.log "Creating child state #{name} with parent #{parent}"
    $stateProvider.state(state)
    state

  buildState 'main', parent: null, url: frontendRoutes.index, loginRequired: false
  buildMapState
    sticky: true,
    reloadOnSearch: false,
    params:
      project_id:
        value: null
        squash: true
      property_id:
        value: null
        squash: true

  buildState 'onboarding',
#    abstract: true
    url: frontendRoutes.onboarding
    loginRequired: false
    permissionsRequired: false

  buildChildState 'onboardingPlan', 'onboarding',
    loginRequired: false
    permissionsRequired: false
    showSteps: false

  rmapsOnboardingOrderServiceProvider.steps.forEach (boardingName) ->
    buildChildState boardingName, 'onboarding',
      url: '/' + (rmapsOnboardingOrderServiceProvider.getId(boardingName) + 1)
      loginRequired: false
      permissionsRequired: false
      showSteps: true

  rmapsOnboardingProOrderServiceProvider.steps.forEach (boardingName) ->
    buildChildState boardingName + 'Pro', 'onboarding',
      controller: "rmaps#{boardingName[0].toUpperCase()}#{boardingName.substr(1)}Ctrl"
      url: '/pro/' + (rmapsOnboardingProOrderServiceProvider.getId(boardingName) + 1)
      templateProvider: ($templateCache) ->
        $templateCache.get "./views/onboarding/#{boardingName}.jade"
      loginRequired: false
      permissionsRequired: false
      showSteps: true

  buildState 'snail'
  buildState 'user'
  buildState 'profiles'
  buildState 'history'
  buildState 'properties'
  buildState 'projects', page: { title: 'Projects' }, mobile: { modal: true }
  buildState 'project', page: { title: 'Project', dynamicTitle: true }, mobile: { modal: true }
  buildChildState 'projectClients', 'project', page: { title: 'My Clients' }, mobile: { modal: true }
  buildChildState 'projectNotes', 'project', page: { title: 'Notes' }, mobile: { modal: true }
  buildChildState 'projectFavorites', 'project', page: { title: 'Favorites' }, mobile: { modal: true }
  buildChildState 'projectNeighbourhoods', 'project', page: { title: 'Neighborhoods' }, mobile: { modal: true }
  buildChildState 'projectPins', 'project', page: { title: 'Pinned Properties' }, mobile: { modal: true }
  buildState 'neighbourhoods'
  buildState 'notes'
  buildState 'favorites'
  buildState 'sendEmailModal'
  buildState 'newEmail'

  buildState 'mail'
  buildState 'mailWizard',
    sticky: true

  buildChildState 'selectTemplate', 'mailWizard'
  buildChildState 'editTemplate', 'mailWizard'
  buildChildState 'senderInfo', 'mailWizard'
  buildChildState 'recipientInfo', 'mailWizard'

  buildState 'login', template: require('../../../common/html/login.jade'), sticky: false, loginRequired: false
  buildState 'logout', sticky: false, loginRequired: false
  buildState 'accessDenied', controller: null, sticky: false, loginRequired: false
  buildState 'authenticating', controller: null, sticky: false, loginRequired: false
  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null, sticky: false, loginRequired: false

  $urlRouterProvider.when '', frontendRoutes.index
