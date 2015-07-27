app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
jobsEditTemplate = require("../../html/views/jobsEdit.jade")

# for documentation, see the following:
#   https://github.com/angular-ui/ui-router/wiki/Nested-States-%26-Nested-Views
#   https://github.com/angular-ui/ui-router/wiki

module.exports = app.config [ '$stateProvider', '$stickyStateProvider', '$urlRouterProvider',

  ($stateProvider, $stickyStateProvider, $urlRouterProvider) ->

    buildState = (name, overrides = {}) ->
      state =
        name:         name
        parent:       'main'
        url:          adminRoutes[name],
        controller:   "rmaps#{name[0].toUpperCase()}#{name.substr(1)}Ctrl"
      _.extend(state, overrides)

      if !state.template
        state.template = require "../../html/views/#{name}.jade"

      # state.template = _getTemplate(state.templatePath)
      # delete state.templatePath
      if state.parent
        state.views = {}
        state.views["#{name}@#{state.parent}"] =
          template: state.template
          controller: state.controller
        delete state.template
        delete state.controller

      $stateProvider.state(state)
      state

    buildState 'main', parent: null, url: adminRoutes.index, sticky: true
    buildState 'home', sticky: true, loginRequired: true
    buildState 'mls', sticky: true, loginRequired: true
    buildState 'normalize', sticky: true, loginRequired: true

    buildState 'jobs', sticky: true, loginRequired: true
    buildState 'jobsCurrent', sticky: true, parent: 'jobs', loginRequired: true
    buildState 'jobsHistory', sticky: true, parent: 'jobs', loginRequired: true
    buildState 'jobsQueue', sticky: true, parent: 'jobs', template: jobsEditTemplate, loginRequired: true
    buildState 'jobsTask', sticky: true, parent: 'jobs', template: jobsEditTemplate, loginRequired: true
    buildState 'jobsSubtask', sticky: true, parent: 'jobs', template: jobsEditTemplate, loginRequired: true

    buildState 'authenticating', controller: null
    buildState 'accessDenied', controller: null
    buildState 'login'
    buildState 'logout'

    # this one has to be last, since it is a catch-all
    buildState 'pageNotFound', controller: null

    $urlRouterProvider.when /\/admin$/, adminRoutes.index
]
