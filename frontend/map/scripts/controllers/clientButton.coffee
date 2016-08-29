###global _, L###
app = require '../app.coffee'
notesTemplate = do require '../../html/views/templates/modals/note.jade'
confirmTemplate = do require '../../html/views/templates/modals/confirm.jade'
originator = 'map'

app.controller 'rmapsClientButtonCtrl', (
$rootScope,
$scope,
$uibModal,
$stateParams,

rmapsPrincipalService,
rmapsClientsFactory
) ->
  
  profile = rmapsPrincipalService.getCurrentProfile()
  clientsService = new rmapsClientsFactory profile.project_id

  loadClients = () ->
    clientsService.getAll()
    .then (clients) ->
      $scope.clients = clients
      $scope.clientTotal = clients.length

  #
  # Scope Event Handlers
  #

  $scope.edit = (client) ->
    $scope.clientCopy = _.clone client || {}
    modalInstance = $uibModal.open
      scope: $scope
      template: require('../../html/views/templates/modals/addClient.jade')()

    $scope.cancelModal = () ->
      modalInstance.dismiss('cancel')

    $scope.saveClient = () ->
      modalInstance.dismiss('save')
      method = if $scope.clientCopy.id? then 'update' else 'create'
      $scope.clientCopy = _.merge $scope.clientCopy, project_name: profile.name
      clientsService[method] $scope.clientCopy
      .then loadClients

  $scope.remove = (client) ->
    clientsService.remove client
    .then loadClients

  loadClients()
