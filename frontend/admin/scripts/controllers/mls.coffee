app = require '../app.coffee'
mlsConfigService = require '../services/mlsConfig.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
modalTemplate = require '../../html/views/templates/newMlsConfig.jade'

app.controller 'rmapsMlsCtrl', [ '$scope', '$state', 'rmapsMlsService', '$modal',
  ($scope, $state, rmapsMlsService, $modal) ->

    console.log 'rmapsMlsCtrl'

    rmapsMlsService.getConfigs()
    .then (configs) ->
      angular.forEach configs, (config) ->
        console.log config

    $scope.mock =
      db: ['dbOne', 'dbTwo']
      table: ['tableOne', 'tableTwo']
      field: ['fieldOne', 'fieldTwo']

    $scope.idOptions = []
    $scope.dbOptions = []
    $scope.tableOptions = []
    $scope.fieldOptions = []

    #$scope.step0.$valid

    $scope.mlsModalData =
      id: null
      name: null
      notes: null
      username: null
      password: null
      url: null
    $scope.animationsEnabled = true
    $scope.open = () ->
      modalInstance = $modal.open
        animation: $scope.animationsEnabled
        #templateUrl: '../../html/views/templates/newMlsConfig.jade'
        #templateUrl: 'templates/newMlsConfig.jade'
        template: modalTemplate
        controller: 'ModalInstanceCtrl'
        resolve:
          mlsModalData: () ->
            return $scope.mlsModalData

      modalInstance.result.then(
        (mlsModalData) ->
          console.log "#### received modal data:"
          console.log mlsModalData
        , () ->
          console.log "#### modal screwed up!"
      )

    $scope.mlsData =
      id: null
      name: null
      notes: null
      active: null
      username: null
      password: null
      url: null
      main_property_data:
        db: null
        table: null
        field: null
        queryTemplate: null
    $scope.adminRoutes = adminRoutes
    $scope.$state = $state

    $scope.step = 0

    isActive = (configStep) ->
      () ->
        return ($scope.step == configStep)

    $scope.formItems = [
      step: 0
      heading: "Select MLS"
      validate: () ->
        id = $scope.mlsData.id
        thisValidates = $scope.step0.$valid
        if thisValidates
          $scope.formItems[1].disabled = false
          console.log "#### Step 1 validated"
      disabled: false
      active: isActive(0)
    ,
      step: 1
      heading: "Choose Database"
      validate: () ->
        thisValidates = true
        if thisValidates
          $scope.formItems[2].disabled = false
          console.log "#### Step 2 validated"
      disabled: true
      active: isActive(1)
    ,
      step: 2
      heading: "Choose Table"
      validate: () ->
        thisValidates = true
        if thisValidates
          $scope.formItems[3].disabled = false
          console.log "#### Step 3 validated"
      disabled: true
      active: isActive(2)
    ,
      step: 3
      heading: "Choose Field"
      validate: () ->
        thisValidates = true
        if thisValidates
          console.log "#### Step 4 validated"
      disabled: true
      active: isActive(3)
    ]

    $scope.proceedTo = (toStep) ->
      thisStep = $scope.step
      if toStep > thisStep
        # run proceed() of this step, which validates
        $scope.formItems[thisStep].validate()

      # incr active step if allowed
      if _.every($scope.formItems[..toStep], {disabled: false}) and toStep < ($scope.formItems.length)
        $scope.step = toStep
      else
        $scope.alert = "Cannot proceed to step #{toStep}!"
        console.log $scope.alert
]


app.controller 'ModalInstanceCtrl', ['$scope', '$modalInstance', 'mlsModalData',
  ($scope, $modalInstance, mlsModalData) ->
    $scope.mlsModalData = mlsModalData;

    $scope.ok = () ->
      $modalInstance.close($scope.mlsModalData)

    $scope.cancel = () ->
      $modalInstance.dismiss('cancel')

]

