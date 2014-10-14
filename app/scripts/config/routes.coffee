app = require '../app.coffee'

#if this configuration gets much larger consider breaking this into a config folder

module.exports = app.config([
  '$routeProvider'
  '$urlRouterProvider'
  ($routeProvider, $urlRouterProvider) ->
#    $urlRouterProvider.otherwise('/')
    $routeProvider
    .when '/map',
      templateUrl: 'views/map.html'
      controller: 'MapCtrl'.ourNs()
    .when '/users',
      templateUrl: 'views/users.html'
      controller: 'UserCtrl'.ourNs()
    .when '/test',
      templateUrl: 'views/test.html'
      controller: 'TestCtrl'.ourNs()
    .when '/',
      templateUrl: 'views/main.html'
      controller: 'MainCtrl'.ourNs()
    .when '/500',
      templateUrl: 'views/500.html'
    .when '/404',
      templateUrl: 'views/404.html'
    .otherwise
        redirectTo: '/'
])