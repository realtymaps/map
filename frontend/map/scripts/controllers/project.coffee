app = require '../app.coffee'
_ = require 'lodash'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app

app.controller 'rmapsProjectCtrl',
($rootScope, $scope, $http, $log, $state, $modal, rmapsPrincipalService, rmapsProjectsService, rmapsClientsFactory, rmapsResultsFormatterService, rmapsPropertyFormatterService, rmapsPropertiesService, rmapsPageService, rmapsevents) ->
  $scope.activeView = 'project'
  $log = $log.spawn("frontend:map:projects")
  $log.debug 'projectCtrl'

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  # Override for property button
  $scope.formatters.results.zoomTo = (result) ->
    $state.go 'map', project_id: $state.params.id, property_id: result.rm_property_id

  $scope.project = null
  clientsService = null

  $scope.getStateName = (name) ->
    name.replace /project(.+)/, '$1'

  $scope.archiveProject = (project, evt) ->
    evt.stopPropagation()
    rmapsProjectsService.update project.id, archived: !project.archived
    .then () ->
      project.archived = !project.archived

  $scope.resetProject = (project) ->
    if confirm 'Clear all filters, saved properties, and notes?'
      rmapsProjectsService.delete id: project.id

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
      toLoad = _.merge {}, project.properties_selected, project.favorites
      if not _.isEmpty toLoad
        $scope.loadProperties toLoad
        .then (properties) ->
          project.properties_selected = _.pick properties, _.keys(project.properties_selected)
          project.favorites = _.pick properties, _.keys(project.favorites)

      clientsService = new rmapsClientsFactory project.id unless clientsService
      $scope.loadClients()

      $scope.project = project

      # Set the project name as the page title
      rmapsPageService.setDynamicTitle(project.name)

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

  $rootScope.$onRootScope rmapsevents.notes, () ->
    $scope.loadProject() unless !$state.params.id

  $rootScope.registerScopeData () ->
    $scope.loadProject()
