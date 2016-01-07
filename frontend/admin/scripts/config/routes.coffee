app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
jobsEditTemplate = require '../../html/views/jobs/jobsEdit.jade'
loginTemplate = require '../../../common/html/login.jade'

# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

stateDefaults =
  sticky: true
  loginRequired: true

app.run ($rootScope) ->
  $rootScope.navbarPages = [
    {state: 'jobs', name: 'Jobs'}
    {state: 'dataSource', name: 'Data Source'}
    {state: 'utils', name: 'Utils'}
  ]
  return

module.exports = app.config ($stateProvider, $stickyStateProvider, $urlRouterProvider) ->

  buildState = (name, overrides = {}) ->
    state =
      name:         name
      parent:       'main'
      url:          adminRoutes[name],
      controller:   "rmaps#{name[0].toUpperCase()}#{name.substr(1)}Ctrl"
    _.extend(state, overrides)
    _.defaults(state, stateDefaults)

    if !state.template
      state.templateProvider = ($templateCache) ->
        templateName = if state.parent == 'main' or state.parent is null then "./views/#{name}.jade" else "./views/#{state.parent}/#{name}.jade"
        console.debug 'loading template:', templateName
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

  buildState 'main', parent: null, url: adminRoutes.index, loginRequired: false
  buildState 'home'

  buildState 'jobs'
  buildState 'jobsCurrent', parent: 'jobs'
  buildState 'jobsHistory', parent: 'jobs'
  buildState 'jobsHealth', parent: 'jobs'
  buildState 'jobsQueue', parent: 'jobs', template: jobsEditTemplate
  buildState 'jobsTask', parent: 'jobs', template: jobsEditTemplate
  buildState 'jobsSubtask', parent: 'jobs', template: jobsEditTemplate

  buildState 'dataSource'
  buildState 'mls', parent: 'dataSource'
  buildState 'normalize', parent: 'dataSource'
  buildState 'county', parent: 'dataSource'

  buildState 'utils'
  buildState 'utilsFipsCodes', parent: 'utils'

  buildState 'authenticating', controller: null, sticky: false, loginRequired: false
  buildState 'accessDenied', controller: null, sticky: false, loginRequired: false
  buildState 'login', template: loginTemplate, sticky: false, loginRequired: false
  buildState 'logout', sticky: false, loginRequired: false

  # this one has to be last, since it is a catch-all
  buildState 'pageNotFound', controller: null, sticky: false, loginRequired: false

  $urlRouterProvider.when /\/admin$/, adminRoutes.index
