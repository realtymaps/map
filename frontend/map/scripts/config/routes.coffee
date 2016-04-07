###global _:true###
app = require '../app.coffee'
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

stateDefaults =
  sticky: false
  loginRequired: true
  persist: false

module.exports = app.config (
  $stateProvider,
  $stickyStateProvider,
  $urlRouterProvider,
  rmapsOnboardingOrderServiceProvider,
  rmapsOnboardingProOrderServiceProvider,

  rmapsRouteIdentityResolve,
  rmapsRouteProfileResolve
) ->

#  $stickyStateProvider.enableDebug(true)

  baseState = (name, overrides = {}) ->
    state =
      name:         name
      parent:       'main'
      url:          frontendRoutes[name],
      #controller:   "rmaps#{name.toInitCaps()}Ctrl"
      controller:   "rmaps#{name[0].toUpperCase()}#{name.substr(1)}Ctrl" # we can have CamelCase yay!
    _.extend(state, overrides)
    _.defaults(state, stateDefaults)

    # Evaluate resolves
    if state.loginRequired
      state.resolve = state.resolve or {}

      # Add a resolve for the current Identity to injectable 'currentIdentity'
      if !state.resolve.currentIdentity
        state.resolve.currentIdentity = rmapsRouteIdentityResolve

      # Add a resolve for the current or requested profile to injectable 'currentProfile'
      if !state.resolve.currentProfile
        state.resolve.currentProfile = rmapsRouteProfileResolve

    return state

  appendTemplateProvider = (name, state) ->
    if !state.template && !state.templateProvider
      state.templateProvider = ($templateCache) ->
        templateName = if state.parent == 'main' or state.parent is null then "./views/#{name}.jade" else "./views/#{state.parent}/#{name}.jade"
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
    state.pageType = state.pageType or 'page'#could already be set from overrides

    $stateProvider.state(state)
    state

  buildChildState = (name, parent, overrides = {}) ->
    state = baseState name, overrides
    state.parent = parent

    appendTemplateProvider name, state
    $stateProvider.state(state)
    state

  buildState 'main', parent: null, url: frontendRoutes.index, loginRequired: false, permissionsRequired: false

  buildMapState
    sticky: true
    reloadOnSearch: false
    projectParam: 'project_id'
    params:
      project_id:
        value: null
        squash: true
      property_id:
        value: null
        squash: true

  buildState 'onboarding',
    abstract: true
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
  buildState 'user',
    page: {title: 'My Account', dynamicTitle: true }
  buildChildState 'userMLS', 'user', page: { title: 'MLS' }
  buildChildState 'userBilling', 'user', page: { title: 'Billing' }
  buildChildState 'userNotifications', 'user', page: { title: 'Notifications' }
  buildChildState 'userTeamMembers', 'user', page: { title: 'Team Members' }

  buildState 'profiles'
  buildState 'history'
  buildState 'properties'
  buildModalState 'property', page: { title: 'Property Detail' }
  buildState 'projects', page: { title: 'Projects' }, mobile: { modal: true }
  buildState 'project',
    projectParam: 'id',
    page: { title: 'Project', dynamicTitle: true },
    mobile: { modal: true },
    resolve:
      currentProfile: ($stateParams, rmapsProjectsService, rmapsProfilesService) ->
        return rmapsProjectsService.getProject $stateParams.id
        .then (project) ->
          return rmapsProfilesService.setCurrentProfileByProjectId $stateParams.id
  buildChildState 'projectClients', 'project', projectParam: 'id', page: { title: 'My Clients' }, mobile: { modal: true }
  buildChildState 'projectNotes', 'project', projectParam: 'id', page: { title: 'Notes' }, mobile: { modal: true }
  buildChildState 'projectFavorites', 'project', projectParam: 'id', page: { title: 'Favorites' }, mobile: { modal: true }
  buildChildState 'projectNeighbourhoods', 'project', projectParam: 'id', page: { title: 'Neighborhoods' }, mobile: { modal: true }
  buildChildState 'projectPins', 'project', projectParam: 'id', page: { title: 'Pinned Properties' }, mobile: { modal: true }
  buildState 'neighbourhoods'
  buildState 'notes'
  buildState 'favorites'

  buildState 'mail', profileRequired: false
  buildState 'mailWizard',
    abstract: true

  buildChildState 'selectTemplate', 'mailWizard'
  buildChildState 'editTemplate', 'mailWizard'
  buildChildState 'campaignInfo', 'mailWizard'
  buildChildState 'recipientInfo', 'mailWizard', params: {property_ids: null}
  buildChildState 'review', 'mailWizard'

  buildState 'login', url: null, template: require('../../../common/html/login.jade'), sticky: false, loginRequired: false
  buildState 'logout', url: null, sticky: false, loginRequired: false
  buildState 'accessDenied', controller: null, sticky: false, loginRequired: false

  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null, sticky: false, loginRequired: false

  $urlRouterProvider.when '', frontendRoutes.index

#
# Log errors in Resolves
#
app.run ($rootScope, $log) ->
  $log = $log.spawn "ui-router"
  $rootScope.$on '$stateChangeError', (event, toState, toParams, fromState, fromParams, error) ->
    $log.error "State change error: ", error
