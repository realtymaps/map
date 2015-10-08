###
 This maps to partial controllers in the mayday project
###
module.exports = (app) ->
  app.controller 'rmapsPropertiesCtrl', ($scope, $http, $routeParams) ->
    $scope.activeView = 'properties'

    $scope.JSONData = []
    $http.get('json/properties.json').success (data) ->
      $scope.JSONData = data
      $scope.singleProperty = $scope.JSONData[$routeParams.id]

  .controller 'rmapsNeighbourhoodsCtrl', ($scope, $http, $routeParams) ->
    $scope.activeView = 'neighbourhoods'

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
        $log.debug 'Modal dismissed at: ' + new Date
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
      $http.get('json/emails.json').success (data) ->
        $scope.JSONData = data
        $scope.singleEmail = $scope.JSONData[$routeParams.id]

      $scope.projectsArray = []
      $http.get('json/projects.json').success((data) ->
        $scope.projectsArray = data
      ).error (data, status, headers, config) ->
        alert status
      $scope.propertiesArray = []
      $http.get('json/properties.json').success((data) ->
        $scope.propertiesArray = data
      ).error (data, status, headers, config) ->
        alert status
      $scope.templatesArray = []
      $http.get('json/email_templates.json').success((data) ->
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
