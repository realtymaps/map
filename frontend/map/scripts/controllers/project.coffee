app = require '../app.coffee'
_ = require 'lodash'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app

app.controller 'rmapsProjectCtrl',
(
  $http,
  $log,
  $modal,
  $rootScope,
  $scope,
  $state,
  rmapsClientsFactory,
  rmapsEventConstants
  rmapsNotesService,
  rmapsPageService,
  rmapsPrincipalService,
  rmapsProfilesService,
  rmapsProjectsService,
  rmapsPropertiesService,
  rmapsPropertyFormatterService,
  rmapsResultsFormatterService,

  currentProfile,
  currentProject
) ->
  $scope.activeView = 'project'
  $log = $log.spawn("map:projects")
  $log.debug 'projectCtrl', currentProfile

  # Current project is injected by route resolves
  project = currentProject
  profile = currentProfile

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  # Override for property button
  $scope.zoomClick = (result) ->
    $state.go 'map', project_id: $state.params.id, property_id: result.rm_property_id
    return false

  $scope.project = null
  $scope.notes = []

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

  loadProject = () ->
    # It is important to load property details before properties are added to scope to prevent template breaking
    toLoad = _.merge {}, project.properties_selected, project.favorites
    if not _.isEmpty toLoad
      loadProperties toLoad
      .then (properties) ->
        project.properties_selected = _.pick properties, _.keys(project.properties_selected)
        project.favorites = _.pick properties, _.keys(project.favorites)

    clientsService = new rmapsClientsFactory project.id unless clientsService
    loadClients()

    loadNotes()

    $scope.project = project

    # Set the project name as the page title
    rmapsPageService.setDynamicTitle(project.name)

  loadProperties = (properties) ->
    rmapsPropertiesService.getProperties _.keys(properties), 'filter'
    .then (result) ->
      for detail in result.data
        properties[detail.rm_property_id] = _.extend detail, savedDetails: properties[detail.rm_property_id]
      properties

  loadClients = () ->
    clientsService.getAll()
    .then (clients) ->
      $scope.project.clients = clients

  loadNotes = () ->
    rmapsNotesService.getList()
    .then (notes) ->
      $scope.notes = notes

  $rootScope.$onRootScope rmapsEventConstants.notes, () ->
    loadProject() unless !$state.params.id

  loadProject()
