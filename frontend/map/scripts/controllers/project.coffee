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
  $timeout,

  rmapsClientsFactory,
  rmapsEventConstants

  rmapsMapAccess,

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
  #
  # Set up Logging
  #

  $log = $log.spawn("map:projects")
  $log.debug 'projectCtrl', currentProfile

  #
  # Current project is injected by route resolves
  #

  project = currentProject
  profile = currentProfile
  properties = []

  #
  # Initialize Scope Variables
  #

  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: new rmapsPropertyFormatterService

  # Override for property button
  $scope.zoomClick = (result) ->
    $state.go 'map', project_id: $state.params.id, property_id: result.rm_property_id
    return false

  $scope.$state = $state
  $scope.project = null
  $scope.newNotes = {}
  $scope.notes = []
  $scope.loadedProperties = false

  clientsService = null

  #
  # Dashboard Map
  #
  dashboardMapAccess = $scope.dashboardMapAccess = rmapsMapAccess.newMapAccess('dashboardMap')

  highlightProperty = (propertyId) ->
    dashboardMapAccess.setPropertyClass(propertyId, 'project-dashboard-icon-saved', true)

  dashboardMapAccess.registerMarkerClick $scope, (event, args) ->
    {leafletEvent, leafletObject, model, modelName, layerName} = args

    if property = properties[modelName]
      property.activeSlide = true
      highlightProperty(property.rm_property_id)

  $scope.onSlideChanged = (nextSlide) ->
    highlightProperty(nextSlide.actual.rm_property_id)

  #
  # Property carousel
  #
  $scope.activeSlide = 0

  #
  # Scope Event Handlers
  #

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

  # Create Note
  $scope.createNote = (project, property) ->
    rmapsNotesService.createFromText(
      $scope.newNotes[property.rm_property_id].text,
      project.project_id,
      property.rm_property_id,
      property.geom_point_json
    ).then () ->
      $rootScope.$emit rmapsEventConstants.notes
      delete $scope.newNotes[property.rm_property_id]

  #
  # Load Project Data
  #

  loadProject = () ->
    # It is important to load property details before properties are added to scope to prevent template breaking
    toLoad = _.merge {}, project.properties_selected, project.favorites
    if not _.isEmpty toLoad
      loadProperties toLoad
      .then (loaded) ->
        properties = loaded
        $scope.pins = _.values(_.pick(properties, _.keys(project.properties_selected)))
        $scope.favorites = _.values(_.pick(properties, _.keys(project.favorites)))
    else
      $scope.loadedProperties = true

        # Highlight the first carousel property on the map
        $scope.dashboardMapAccess.initPromise.then () ->
          if $scope.pins.length
            $timeout(() ->
              highlightProperty($scope.pins[0].rm_property_id)
            , 0)

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

      $timeout(() ->
        dashboardMapAccess.addPropertyMarkers(result.data)
        dashboardMapAccess.fitToBounds(result.data)
      , 0)

      return properties
    .finally () ->
      $scope.loadedProperties = true

  loadClients = () ->
    clientsService.getAll()
    .then (clients) ->
      $scope.clients = clients

  loadNotes = () ->
    rmapsNotesService.getList()
    .then (notes) ->
      $scope.notes = notes

  $rootScope.$onRootScope rmapsEventConstants.notes, () ->
    loadProject() unless !$state.params.id

  loadProject()
