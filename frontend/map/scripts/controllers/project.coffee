app = require '../app.coffee'
_ = require 'lodash'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

module.exports = app

app.controller 'rmapsProjectCtrl',
(
  $http,
  $log,
  $uibModal,
  $rootScope,
  $scope,
  $state,
  $timeout,

  rmapsClientsFactory,
  rmapsEventConstants
  rmapsDrawnUtilsService

  rmapsMapAccess,
  rmapsPropertyMarkerGroup,

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
  properties = []

  #
  # Initialize Scope Variables
  #

  $scope.profile = currentProfile
  $scope.propertiesService = rmapsPropertiesService
  $scope.formatters =
    results: new rmapsResultsFormatterService scope: $scope
    property: rmapsPropertyFormatterService

  # Override for property button
  $scope.zoomClick = (result) ->
    $state.go 'map', project_id: $state.params.id, property_id: result.rm_property_id
    return false

  $scope.$state = $state
  $scope.project = null

  # Scope model object allowing the children to manipulate data loaded by this parent controller
  $scope.projectModel = projectModel = {}
  projectModel.areas = []
  projectModel.loadedAreas = false

  $scope.newNotes = {}
  $scope.notes = []
  $scope.loadedProperties = false

  clientsService = null


  #
  # Dashboard Map
  #
  dashboardMapAccess = $scope.dashboardMapAccess = rmapsMapAccess.newMapAccess('dashboardMap')
  dashboardMapAccess.addMarkerGroup(new rmapsPropertyMarkerGroup('property'))
#  dashboardMapAccess.addMarkerGroup(new rmapsMailMarkerGroup('mail'))
#  dashboardMapAccess.addMarkerGroup(new rmapsPropertyGeoJsonGroup('bounds'))
#  dashboardMapAccess.addMarkerGroup(new rmapsFilterSummaryGroup('filterSummary'))

  # Highlight markers on the map when selected
  highlightProperty = (propertyId) ->
    dashboardMapAccess.groups.property.setPropertyClass(propertyId, 'project-dashboard-icon-saved', true)

  # Listen for property marker event clicks
  dashboardMapAccess.groups.property.registerClickHandler $scope, (event, args, propertyId) ->
    if property = properties[propertyId]
      property.activeSlide = true
      highlightProperty(propertyId)

  # When the carousel changes, highlight the selected property on the map
  $scope.onSlideChanged = ({slide}) ->
    highlightProperty(slide.actual.rm_property_id)

  $scope.getLabel = (actual) ->
    if !actual
      return
    "#{actual.address.street} #{actual.address.unit}"
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
    rmapsProjectsService.archive project

  $scope.resetProject = (project) ->
    if confirm 'Clear all filters, saved properties, and notes?'
      rmapsProjectsService.delete id: project.id

  $scope.removeClient = (client) ->
    clientsService.remove client
    .then loadClients

  $scope.editClient = (client) ->
    $scope.clientCopy = _.clone client || {}
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../html/views/templates/modals/addClient.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveClient = () ->
      modalInstance.dismiss('save')
      method = if $scope.clientCopy.id? then 'update' else 'create'
      $scope.clientCopy = _.merge $scope.clientCopy, project_name: $scope.project.name
      clientsService[method] $scope.clientCopy
      .then () ->
        loadClients()

  $scope.editProject = (project) ->
    $scope.projectCopy = _.clone project || {}

    modalInstance = $uibModal.open
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

  $scope.createNote = (project, property) ->
    rmapsNotesService.createNote({project, property, $scope})

  $scope.createProjectNote = (project) ->
    rmapsNotesService.createProjectNote({project, $scope})

  $scope.goDashboardState = (state, params = {}) ->
    params.scrollTo = 'project-dashboard'
    $state.go state, params

  $scope.propertyClick = (propertyId) ->
    if (propertyId)
      $scope.goDashboardState('property', { id: propertyId })

  #
  # Load Project Data
  #

  loadProject = () ->
    # It is important to load property details before properties are added to scope to prevent template breaking
    toLoad = _.merge {}, project.pins, project.favorites
    if not _.isEmpty toLoad
      loadProperties toLoad
      .then (loaded) ->
        properties = loaded
        $scope.pins = _.values(_.pick(properties, _.keys(project.pins)))
        $scope.favorites = _.values(_.pick(properties, _.keys(project.favorites)))

        # Highlight the first carousel property on the map
        dashboardMapAccess.initPromise.then () ->
          if $scope.pins.length
            $timeout(() ->
              highlightProperty($scope.pins[0].rm_property_id)
            , 0)

    else
      $scope.loadedProperties = true

    #
    # Load supporting data
    #
    clientsService = new rmapsClientsFactory(project.id) if !clientsService
    loadClients()
    loadNotes()
    loadAreas()

    $scope.project = project

    # Set the project name as the page title
    rmapsPageService.setDynamicTitle(project.name)

  loadProperties = (properties) ->
    rmapsPropertiesService.getProperties _.keys(properties), 'filter'
    .then (result) ->
      for detail in result.data
        properties[detail.rm_property_id] = _.extend detail, savedDetails: properties[detail.rm_property_id]

      #
      # Add property markers to the dashboard map
      #
      $timeout(() ->
        dashboardMapAccess.groups.property.addPropertyMarkers(result.data)
        dashboardMapAccess.groups.property.fitToBounds(result.data)
      , 0)

      return properties
    .finally () ->
      $scope.loadedProperties = true

  #
  # Load Clients
  #
  loadClients = () ->
    clientsService.getAll()
    .then (clients) ->
      $scope.project.clients = clients

  #
  # Load Notes
  #
  loadNotes = () ->
    rmapsNotesService.getList()
    .then (notes) ->
      $scope.notes = notes

  $rootScope.$onRootScope rmapsEventConstants.notes, () ->
    loadProject() unless !$state.params.id

  #
  # Load Areas
  #

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()

  loadAreas = (cache) ->
    drawnShapesSvc.getAreasNormalized(cache)
    .then (data) ->
      projectModel.areas = data
      projectModel.loadedAreas = true

  #
  # Start initial data load
  #
  loadProject()
