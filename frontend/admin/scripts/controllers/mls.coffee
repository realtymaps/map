_ = require 'lodash'
app = require '../app.coffee'
mlsConfigService = require '../services/mlsConfig.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
modalTemplate = require '../../html/views/templates/newMlsConfig.jade'

app.controller 'rmapsMlsCtrl', [ '$scope', '$state', 'rmapsMlsService', '$modal', 'Restangular',
  ($scope, $state, rmapsMlsService, $modal, Restangular) ->

    console.log 'rmapsMlsCtrl'

    rmapsMlsService.getConfigs()
    .then (configs) ->
      $scope.idOptions = configs
      console.log "#### configs:"
      console.log $scope.idOptions

    $scope.mock =
      db: ['dbOne', 'dbTwo']
      table: ['tableOne', 'tableTwo']
      field: ['fieldOne', 'fieldTwo']

    $scope.dbOptions = []
    $scope.tableOptions = []
    $scope.fieldOptions = []


    $scope.mlsData =
      current:
        id: null
        name: null
        notes: ""
        active: false
        username: null
        password: null
        url: null
        main_property_data: {}

    # $scope.mlsModalData =
    #   id: null
    #   name: null
    #   notes: null
    #   username: null
    #   password: null
    #   url: null
    $scope.animationsEnabled = true
    $scope.open = () ->
      modalInstance = $modal.open
        animation: $scope.animationsEnabled
        template: modalTemplate
        controller: 'ModalInstanceCtrl'
        resolve:
          mlsModalData: () ->
            return $scope.mlsData.current

      modalInstance.result.then(
        (mlsModalData) ->
          console.log "#### received modal data:"
          console.log mlsModalData
          newMls = Restangular.one('/api/mls_config')
          _.merge newMls, mlsModalData

          newMls.post().then (res) ->
            console.log "#### res:"
            console.log res
            console.log "#### newMls"
            console.log newMls
            if res
              $scope.idOptions.push(newMls)
              $scope.mlsData.current = newMls
          #debugger
          # rmapsMlsService.postConfig($scope.mlsData.current)
          # .then (res) ->

          $scope.proceedTo(1)
        , () ->
          console.log "#### modal screwed up!"
      )

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
        thisValidates = true#$scope.step0.$valid
        if thisValidates
          $scope.formItems[1].disabled = false
          console.log "#### Step 1 validated"
      disabled: false
      active: isActive(0)
    ,
      step: 1
      heading: "Choose Database"
      validate: () ->
        thisValidates = $scope.step1.$valid
        if thisValidates
          $scope.formItems[2].disabled = false
          console.log "#### Step 2 validated"
      disabled: true
      active: isActive(1)
    ,
      step: 2
      heading: "Choose Table"
      validate: () ->
        thisValidates = $scope.step2.$valid
        if thisValidates
          $scope.formItems[3].disabled = false
          console.log "#### Step 3 validated"
      disabled: true
      active: isActive(2)
    ,
      step: 3
      heading: "Choose Field"
      validate: () ->
        thisValidates = $scope.step3.$valid
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

