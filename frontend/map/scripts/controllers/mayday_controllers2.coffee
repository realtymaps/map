###
 This maps to partial controllers in the mayday project
###
module.exports = (app) ->
  app.controller 'PropertiesCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/properties.json').success (data) ->
      $scope.JSONData = data
      $scope.singleProperty = $scope.JSONData[$routeParams.id]

  .controller 'ProjectsCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/projects.json').success (data) ->
      $scope.JSONData = data
      $scope.singleProject = $scope.JSONData[$routeParams.id]

  .controller 'NeighbourhoodsCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/neighbourhoods.json').success (data) ->
      $scope.JSONData = data
      $scope.singleNeighbourhoods = $scope.JSONData[$routeParams.id]

  .controller 'NotesCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/notes.json').success (data) ->
      $scope.JSONData = data
      $scope.singleNote = $scope.JSONData[$routeParams.id]

  .controller 'FavoritesCtrl',
    ($scope, $http, $routeParams) ->
      $scope.JSONData = []
      $http.get('data/favorites.json').success (data) ->
        $scope.JSONData = data
        $scope.singleFavorite = $scope.JSONData[$routeParams.id]

  .controller 'AddProjectCtrl',
    ($scope, $http, $routeParams, $modal, $location, $log) ->
      $scope.items = [
        'item1'
        'item2'
        'item3'
      ]
      $scope.animationsEnabled = true
      modalInstance = $modal.open(
        animation: $scope.animationsEnabled
        templateUrl: 'modalContent.html'
        controller: 'ModalAddProjectCtrl'
        resolve: items: ->
          $scope.items
      )
      modalInstance.result.then ((selectedItem) ->
        $scope.selected = selectedItem
      ), ->
        $log.info 'Modal dismissed at: ' + new Date
        $location.path '/map'

  .controller 'ModalAddProjectCtrl', ($scope, $modalInstance, items, $location) ->
    #$scope.showAddClientInfo = false;

    $scope.addClientInfo = ->
      #$scope.showAddClientInfo = true;
      return

    $scope.save = ->
      alert 'saved'
      $location.path '/map'
      $modalInstance.close $scope.selected.item
      return

    $scope.cancel = ->
      $modalInstance.dismiss 'cancel'
      $location.path '/map'
      return

    return
  .controller 'SendEmailModalCtrl',
    ($scope, $http, $routeParams, $modal, $location, $log) ->
      $scope.items = [
        'item1'
        'item2'
        'item3'
      ]
      $scope.animationsEnabled = true
      modalInstance = $modal.open(
        animation: $scope.animationsEnabled
        templateUrl: 'modalSendEmail.html'
        controller: 'ModalSendEmailCtrl'
        resolve: items: ->
          $scope.items
      )
      modalInstance.result.then ((selectedItem) ->
        $scope.selected = selectedItem
        return
      ), ->
        $log.info 'Modal dismissed at: ' + new Date
        $location.path '/map'
        return
      return

  .controller 'ModalSendEmailCtrl', ($scope, $modalInstance, items, $location) ->
    $scope.showActive = 'select-recipients'

    $scope.next = (section_id) ->
      $scope.showActive = section_id
      return

    $scope.back = (section_id) ->
      $scope.showActive = section_id
      return

    $scope.save = ->
      alert 'saved'
      $location.path '/map'
      $modalInstance.close $scope.selected.item
      return

    $scope.cancel = ->
      $modalInstance.dismiss 'cancel'
      $location.path '/map'
      return

    return

  .controller 'NewEmailCtrl',
    ($scope, $http, $routeParams) ->
      $scope.JSONData = []
      $http.get('data/emails.json').success (data) ->
        $scope.JSONData = data
        $scope.singleEmail = $scope.JSONData[$routeParams.id]
        return
      $scope.projectsArray = []
      $http.get('data/projects.json').success((data) ->
        $scope.projectsArray = data
        return
      ).error (data, status, headers, config) ->
        alert status
        return
      $scope.propertiesArray = []
      $http.get('data/properties.json').success((data) ->
        $scope.propertiesArray = data
        return
      ).error (data, status, headers, config) ->
        alert status
        return
      $scope.templatesArray = []
      $http.get('data/email_templates.json').success((data) ->
        $scope.templatesArray = data
        return
      ).error (data, status, headers, config) ->
        alert status
        return
      $scope.waitForTemplate = true

      $scope.selectTemplate = (id) ->
        $scope.waitForTemplate = false
        return

      $scope.radioFontFamilyModel = 'helvetica'
      $scope.radioFontSizeModel = '13'
      $scope.radioFontColorModel = 'black'
      $scope.activeStep = 'recipient'

      $scope.setActiveStep = (stepName) ->
        $scope.activeStep = stepName
