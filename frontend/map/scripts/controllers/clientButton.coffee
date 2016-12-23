_ = require 'lodash'
app = require '../app.coffee'

app.controller 'rmapsClientButtonCtrl', (
$rootScope
$scope
$uibModal
$stateParams
$log
rmapsPrincipalService
rmapsClientsFactory
) ->

  $log = $log.spawn 'rmapsClientButtonCtrl'

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

    $scope.saveClient = (form) ->
      modalInstance.dismiss('save')
      method = if $scope.clientCopy.id? then 'update' else 'create'
      $scope.clientCopy = _.merge $scope.clientCopy, project_name: profile.name
      clientsService[method] $scope.clientCopy
      .then loadClients
      .then () ->
        $log.debug -> "clientCopy:\n#{JSON.stringify($scope.clientCopy)}"
        $uibModal.open
          scope: $scope
          template: require('../../html/views/templates/modals/confirm.jade')()

        $scope.modalTitle = "Client as been invited."
        $scope.modalBody = "#{$scope.clientCopy.first_name} #{$scope.clientCopy.last_name} will receive an email invitation at " +
        "#{$scope.clientCopy.email} to access project #{$scope.clientCopy.project_name}"

  $scope.remove = (client) ->
    clientsService.remove client
    .then loadClients

  loadClients()
