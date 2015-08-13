###
 This maps to partial controllers in the mayday project
###
module.exports = (app) ->
  app.controller 'rmapsPropertiesCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/properties.json').success (data) ->
      $scope.JSONData = data
      $scope.singleProperty = $scope.JSONData[$routeParams.id]

  .controller 'rmapsProjectsCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/projects.json').success (data) ->
      $scope.JSONData = data
      $scope.singleProject = $scope.JSONData[$routeParams.id]

  .controller 'rmapsNeighbourhoodsCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/neighbourhoods.json').success (data) ->
      $scope.JSONData = data
      $scope.singleNeighbourhoods = $scope.JSONData[$routeParams.id]

  .controller 'rmapsNotesCtrl', ($scope, $http, $routeParams) ->
    $scope.JSONData = []
    $http.get('data/notes.json').success (data) ->
      $scope.JSONData = data
      $scope.singleNote = $scope.JSONData[$routeParams.id]

  .controller 'rmapsFavoritesCtrl',
    ($scope, $http, $routeParams) ->
      $scope.JSONData = []
      $http.get('data/favorites.json').success (data) ->
        $scope.JSONData = data
        $scope.singleFavorite = $scope.JSONData[$routeParams.id]

  .controller 'rmapsAddProjectCtrl',
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

  .controller 'rmapsModalAddProjectCtrl', ($scope, $modalInstance, items, $location) ->
    #$scope.showAddClientInfo = false;

    $scope.addClientInfo = ->
      #$scope.showAddClientInfo = true;

    $scope.save = ->
      alert 'saved'
      $location.path '/map'
      $modalInstance.close $scope.selected.item

    $scope.cancel = ->
      $modalInstance.dismiss 'cancel'
      $location.path '/map'

  .controller 'rmapsSendEmailModalCtrl',
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
      ), ->
        $log.info 'Modal dismissed at: ' + new Date
        $location.path '/map'

  .controller 'rmapsModalSendEmailCtrl', ($scope, $modalInstance, items, $location) ->
    $scope.showActive = 'select-recipients'

    $scope.next = (section_id) ->
      $scope.showActive = section_id

    $scope.back = (section_id) ->
      $scope.showActive = section_id

    $scope.save = ->
      alert 'saved'
      $location.path '/map'
      $modalInstance.close $scope.selected.item

    $scope.cancel = ->
      $modalInstance.dismiss 'cancel'
      $location.path '/map'

  .controller 'rmapsNewEmailCtrl',
    ($scope, $http, $routeParams) ->
      $scope.JSONData = []
      $http.get('data/emails.json').success (data) ->
        $scope.JSONData = data
        $scope.singleEmail = $scope.JSONData[$routeParams.id]

      $scope.projectsArray = []
      $http.get('data/projects.json').success((data) ->
        $scope.projectsArray = data
      ).error (data, status, headers, config) ->
        alert status
      $scope.propertiesArray = []
      $http.get('data/properties.json').success((data) ->
        $scope.propertiesArray = data
      ).error (data, status, headers, config) ->
        alert status
      $scope.templatesArray = []
      $http.get('data/email_templates.json').success((data) ->
        $scope.templatesArray = data
      ).error (data, status, headers, config) ->
        alert status
      $scope.waitForTemplate = true

      $scope.selectTemplate = (id) ->
        $scope.waitForTemplate = false

      $scope.radioFontFamilyModel = 'helvetica'
      $scope.radioFontSizeModel = '13'
      $scope.radioFontColorModel = 'black'
      $scope.activeStep = 'recipient'

      $scope.setActiveStep = (stepName) ->
        $scope.activeStep = stepName