###
webpack-stream is responsible for defining what files are being processed see

See /gulp/task/webpack and see /gulp/paths.coffee
###
# main app controller
app = require '../app.coffee'
module.exports = app.controller 'rmapsMainCtrl', ($scope, $timeout) ->
  $scope.isReady = false

  getWelcomeClass = () ->
    $scope.isReady = false
    rnd = Math.round(Math.random() * (3 - 1)) + 1
    cssClass = 'welcome-' + rnd.toString()
    #delay isReady to allow the css to load the image prior to rendering
    $timeout ->
      $scope.isReady = true
    , 200
    cssClass

  $scope.welcomeClass = getWelcomeClass()

  $scope.getIsReady = () ->
    $scope.isReady && $scope.$state.is('main')
