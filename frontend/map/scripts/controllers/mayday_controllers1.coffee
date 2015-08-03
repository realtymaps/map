frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

#maydya .js
module.exports = (app) ->
  ###Bootstrap UI controllers###

  app.controller 'DropdownCtrl', ($scope) ->
    $scope.isOpened = false
    $scope.status = isopen: false

    $scope.toggleDropdown = ($event) ->
      $event.preventDefault()
      $event.stopPropagation()
      $scope.status.isopen = !$scope.status.isopen
      $scope.isOpened = !$scope.isOpened
      return

    $scope.toggled = (open) ->
      $scope.isOpened = open

  .controller 'PopoverCtrl', ($scope) ->
    $scope.staticPopover = title: 'Title'
    $scope.dynamicPopover =
      content: 'Hello, World!'
      templateUrl: 'PopoverTemplate.html'
      title: 'Title'
    $scope.layersPopover =
      content: 'Hello, World!'
      templateUrl: 'LayersPopover.html'
      title: 'Title'

    $scope.close = ->
      sav = @tt_isOpen
      #so first reset all popovers element trigger status
      popovers = document.querySelectorAll('[popover]')
      _.forEach popovers, (popover) ->
        `var popovers`
        angular.element(popover).scope().tt_isOpen = false
        return
      #put back the status of the clicked element
      @tt_isOpen = sav
      #then remove all popover divs
      popovers = document.querySelectorAll('.popover')
      _.forEach popovers, (popover) ->
        angular.element(popover).remove()

  .controller 'CheckboxCtrl', ($scope) ->
    $scope.checkModel = setBeds:
      one: false
      two: false
      three: false
      four: false
      five: false

  .controller 'MobilePageCtrl', ($scope) ->
    $scope.isOn = false

    $scope.toggleIsOn = ->
      $scope.isOn = if $scope.isOn == false then true else false

  .controller 'SearchController', ($scope, $http) ->
      $scope.searchType = 'Properties'

      $scope.setSearchScope = (val) ->
        $scope.searchType = val

  .controller 'rmapsMailCtrl', ($scope, $http) ->
      $scope.emailsArray = []

      ###emails json###

      $http.get(frontendRoutes.mocks.email).success((response) ->
        $scope.emailsArray = response
      ).error (data, status, headers, config) ->
        alert status


  .controller 'rmapsHistoryCtrl', ($scope, $http) ->
      $scope.historyArray = []

      ###emails json###

      $http.get(frontendRoutes.mocks.history).success((response) ->
        $scope.historyArray = response
      ).error (data, status, headers, config) ->
        alert status

  .controller 'ContentController', ($scope) ->
