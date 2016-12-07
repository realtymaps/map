app = require '../app.coffee'
_ = require 'lodash'

app.controller 'rmapsMapAreasCtrl', (
  $rootScope,
  $scope,
  $http,
  $log,
  rmapsDrawnUtilsService,
  rmapsEventConstants) ->

  drawnShapesSvc = rmapsDrawnUtilsService.createDrawnSvc()
  $log = $log.spawn("map:areas")

  getAll = ({cache, fromDrawing}) ->
    drawnShapesSvc.getAreasNormalized(cache)
    .then (data) ->
      $log.debug data

      # Enable areas layer if a new area is found after initial load
      if $scope.areas && !fromDrawing
        existingById = _.indexBy $scope.areas, 'properties.id'
        newById = _.indexBy data, 'properties.id'
        $log.debug existingById
        newAreas = _.filter(data, (d) -> !existingById[d.properties.id])
        if newAreas.length
          $log.debug newAreas
          $rootScope.$emit rmapsEventConstants.areas.addDrawItem, newAreas
        removedAreas = _.filter($scope.areas, (d) -> !newById[d.properties.id])
        for area in removedAreas
          $rootScope.$emit rmapsEventConstants.areas.removeDrawItem, area

      $scope.areas = data

  $scope.areaListToggled = (isOpen) ->
    if isOpen
      getAll({cache:false})
    $rootScope.$emit rmapsEventConstants.areas.dropdownToggled, isOpen

  #
  # Listen for updates to the list by create/remove
  #

  $scope.$onRootScope rmapsEventConstants.areas, () ->
    getAll({cache:false,fromDrawing:true})

  #
  # Load the area list
  #
  getAll({cache:false})
