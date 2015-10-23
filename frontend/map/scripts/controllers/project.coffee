app = require '../app.coffee'
_ = require 'lodash'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app

app.controller 'rmapsProjectCtrl', ($rootScope, $scope, $http, $log, $state, $modal, rmapsprincipal, rmapsProjectsService, rmapsClientsService, rmapsResultsFormatter) ->
  $scope.activeView = 'project'
  $log = $log.spawn("map:projects")
  $log.debug 'projectCtrl'

  $scope.formatters = new rmapsResultsFormatter scope: $watch: () ->
  $scope.selected = 'project'
  $scope.project = null
  clientsService = null

  $scope.archiveProject = (project, evt) ->
    evt.stopPropagation()
    rmapsProjectsService.archive project

  $scope.removeClient = (client) ->
    clientsService.remove client
    .then $scope.loadClients

  $scope.editClient = (client) ->
    $log.debug 'add/edit client'
    $log.debug client

    $scope.clientCopy = _.clone client || {}
    modalInstance = $modal.open
      scope: $scope
      template: require('../../html/views/templates/modals/addClient.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveClient = () ->
      modalInstance.dismiss('save')
      method = if $scope.clientCopy.id? then 'update' else 'create'
      clientsService[method] $scope.clientCopy
      .then $scope.loadClients

  $scope.editProject = (project) ->
    $scope.projectCopy = _.clone project || {}

    modalInstance = $modal.open
      animation: true
      scope: $scope
      template: require('../../html/views/templates/modals/editProject.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveProject = () ->
      modalInstance.dismiss('save')
      rmapsProjectsService.saveProject $scope.projectCopy
      .then () ->
        _.assign $scope.project, $scope.projectCopy

  $scope.getPropertyDetail = (property) ->
    $http.get backendRoutes.properties.details, params: rm_property_id: property.rm_property_id, columns: 'detail'
    .then (result) ->
      $scope.propertyDetail = _.pairs result.data[0]
      modalInstance = $modal.open
        animation: true
        scope: $scope
        template: require('../../html/views/templates/modals/propertyDetail.jade')()

  $scope.loadProject = () ->
    rmapsProjectsService.getProject $state.params.id
    .then (project) ->
      $scope.project = project

      $scope.loadProperties()

      clientsService = new rmapsClientsService project.id unless clientsService
      $scope.loadClients()

  $scope.loadProperties = () ->
    propertyIds = _.keys $scope.project.properties_selected
    $scope.project.propertiesTotal = propertyIds.length
    $http.get backendRoutes.properties.details, params: rm_property_id: propertyIds, columns: 'filter'
    .then (result) ->
      for detail in result.data
        _.extend $scope.project.properties_selected[detail.rm_property_id], detail

  $scope.loadClients = () ->
    clientsService.getAll()
    .then (clients) ->
      $scope.project.clients = clients

  $rootScope.registerScopeData $scope.loadProject
