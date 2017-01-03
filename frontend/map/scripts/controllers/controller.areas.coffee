app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsMapAreasCtrl', (
$rootScope,
$scope,
$http,
$log,
rmapsDrawnUtilsService,
rmapsEventConstants,
toastr) ->

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()
  $log = $log.spawn("map:areas")

  getAreas = ({cache, fromDrawing} = {}) ->
    drawnShapesSvc.getAreasNormalized(cache)
    .then (data) ->
      $log.debug data

      # Enable areas layer if a new area is found after initial load
      if $scope.areas && !fromDrawing
        existingById = _.indexBy $scope.areas, 'properties.id'
        newById = _.indexBy data, 'properties.id'
        newAreas = _.filter(data, (d) -> !existingById[d.properties.id])
        if newAreas.length
          $rootScope.$emit rmapsEventConstants.areas.addDrawItem, newAreas
          areaToast = toastr.info "A new area was added by a collaborator", 'New Area Added',
            closeButton: true
            timeOut: 0
            onHidden: (hidden) ->
              toastr.clear areaToast

        removedAreas = _.filter($scope.areas, (d) -> !newById[d.properties.id])
        for area in removedAreas
          $rootScope.$emit rmapsEventConstants.areas.removeDrawItem, area

      $scope.areas = data

  $scope.map.getAreas = _.throttle getAreas, 30000, leading: true, trailing: false

  $scope.areaListToggled = (isOpen) ->
    if isOpen
      getAreas({cache:false})
    $rootScope.$emit rmapsEventConstants.areas.dropdownToggled, isOpen

  #
  # Listen for updates to the list by create/remove
  #

  $scope.$onRootScope rmapsEventConstants.areas, () ->
    getAreas({cache:false,fromDrawing:true})

  #
  # Load the area list
  #
  getAreas({cache:false})
