app = require '../app.coffee'
_ = require 'lodash'

module.exports = app

app.controller 'rmapsProjectCtrl', ($rootScope, $scope, $http, $log, $state, $modal, rmapsprincipal, rmapsProjects) ->
  $scope.activeView = 'project'
  $log = $log.spawn("map:projects")
  $log.debug 'projectCtrl'

  $scope.selected = 'project'
  $scope.project = null

  $scope.archiveProject = (project, evt) ->
    evt.stopPropagation()
    rmapsProjects.archive project

  $scope.loadProject = (id) ->
    rmapsProjects.getProject id
    .then (project) ->
      $scope.project = project
    .catch (error) ->
      $log.error error

  $scope.editProject = (project) ->
    $scope.projectCopy = _.clone project

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/editProject.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveProject = () ->
      modalInstance.dismiss('save')
      rmapsProjects.saveProject $scope.projectCopy
      .then (response) ->
        _.extend $scope.project, $scope.projectCopy

  $rootScope.registerScopeData () ->
    if $state.params.id
      $scope.loadProject($state.params.id)
