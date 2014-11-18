app = require '../app.coffee'

#if this configuration gets much larger consider breaking this into a config folder

module.exports = app.config([ '$routeProvider', '$urlRouterProvider',
  ($routeProvider) ->
    $routeProvider
    .when '/map',
      template: require('../../html/views/map.jade')
      controller: 'MapCtrl'.ourNs()
    .when '/users',
      template: require('../../html/views/users.html')
      controller: 'UserCtrl'.ourNs()
    .when '/login',
      template: require('../../html/views/login.jade')
      controller: 'LoginCtrl'.ourNs()
    .when '/',
      template: require('../../html/views/main.html')
      controller: 'MainCtrl'.ourNs()
    .when '/500',
      template: require('../../html/views/500.html')
    .when '/404',
      template: require('../../html/views/404.html')
    .otherwise template: require('../../html/views/404.html')
])
