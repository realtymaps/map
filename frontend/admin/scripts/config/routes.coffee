app = require '../app.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'

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
        template:     require("../../html/views/#{name}.jade")
        controller:   "rmaps#{name[0].toUpperCase()}#{name.substr(1)}Ctrl"
      _.extend(state, overrides)
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
    buildState 'home'
    buildState 'mls'
    
    # this one has to be last, since it is a catch-all
    buildState 'pageNotFound', controller: null

    $urlRouterProvider.when '/admin/', adminRoutes.home
]
