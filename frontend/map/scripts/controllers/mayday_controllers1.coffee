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

  .controller 'PageCtrl', ($scope, $location) ->
      $scope.isOn = false

      $scope.toggleIsOn = ->
        $scope.isOn = if $scope.isOn == false then true else false

      ###active view###

      $scope.activeView = 'map'

      ###relocate to map view at start###

      $location.path '/map'

      $scope.isActive = (viewLocation) ->
        `var locationView`
        locationPath = $location.path().substr(1)
        if locationPath.lastIndexOf('/') > 0
          locationView = locationPath.slice(0, locationPath.lastIndexOf('/'))
        else
          locationView = $location.path().substr(1)
        active = viewLocation == locationView
        if active
          $scope.activeView = viewLocation
        active

      $scope.toggleMainOn = false

      $scope.toggleMainNav = ->
        $scope.toggleMainOn = if $scope.toggleMainOn == false then true else false
        return

      $scope.addProject = ->
        $location.path '/add_project'
        return

      $scope.openEmailModal = ->
        $location.path '/send_email_modal'
        return

      $scope.createNewEmail = ->
        $scope.activeView = 'create-new-email'
        $location.path '/create_new_email'

  .controller 'SearchController', ($scope, $http) ->
      $scope.searchType = 'Properties'

      $scope.setSearchScope = (val) ->
        $scope.searchType = val
        return

      return

  .controller 'EmailController', ($scope, $http) ->
      $scope.emailsArray = []

      ###emails json###

      $http.get(dataLocation + 'emails.json').success((response) ->
        $scope.emailsArray = response
      ).error (data, status, headers, config) ->
        alert status


  .controller 'HistoryController', ($scope, $http) ->
      $scope.historyArray = []

      ###emails json###

      $http.get(dataLocation + 'activity.json').success((response) ->
        $scope.historyArray = response
      ).error (data, status, headers, config) ->
        alert status

  .controller 'ContentController', ($scope) ->
