app = require '../app.coffee'
_ = require 'lodash'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app

app.controller 'rmapsProjectCtrl', ($rootScope, $scope, $http, $log, $state, $modal, rmapsprincipal, rmapsProjectsService, rmapsClientsService, rmapsResultsFormatter, rmapsPropertiesService) ->
  $scope.activeView = 'project'
  $log = $log.spawn("map:projects")
  $log.debug 'projectCtrl'

  $scope.formatters = results: new rmapsResultsFormatter scope: $scope

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
    rmapsPropertiesService.getProperties property.rm_property_id, 'detail'
    .then (result) ->
      $scope.propertyDetail = _.pairs result.data[0]
      modalInstance = $modal.open
        animation: true
        scope: $scope
        template: require('../../html/views/templates/modals/propertyDetail.jade')()

  $scope.loadProject = () ->
    rmapsProjectsService.getProject $state.params.id
    .then (project) ->
      # It is important to load property details before properties are added to scope to prevent template breaking
      $scope.loadProperties project.properties_selected
      .then (properties) ->
        project.properties_selected = properties
        project.propertiesTotal = _.keys(properties).length

      project.properties_selected = null

      clientsService = new rmapsClientsService project.id unless clientsService
      $scope.loadClients()

      $scope.project = project

  $scope.loadProperties = (properties) ->
    rmapsPropertiesService.getProperties _.keys(properties), 'filter'
    .then (result) ->
      for detail in result.data
        properties[detail.rm_property_id] = _.extend detail, savedDetails: properties[detail.rm_property_id]
      properties

  $scope.loadClients = () ->
    clientsService.getAll()
    .then (clients) ->
      $scope.project.clients = clients

  $rootScope.registerScopeData () ->
    $scope.selected = $state.params.selected or 'project'
    $scope.loadProject()
