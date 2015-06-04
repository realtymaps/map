_ = require 'lodash'
app = require '../app.coffee'
mlsConfigService = require '../services/mlsConfig.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
modalTemplate = require '../../html/views/templates/newMlsConfig.jade'

app.controller 'rmapsMlsCtrl', [ '$scope', '$state', 'rmapsMlsService', '$modal', 'Restangular', '$q',
  ($scope, $state, rmapsMlsService, $modal, Restangular, $q) ->

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
        main_property_data: {"queryTemplate": "[(__FIELD_NAME__=]YYYY-MM-DD[T]HH:mm:ss[+)]"}

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
          rmapsMlsService.postConfig(mlsModalData, $scope.idOptions).then (newMls) ->
            $scope.mlsData.current = newMls
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
      process: () ->
        console.log "Processing step 0..."
        if $scope.mlsData.current.id
          console.log "populating dbOptions with id=#{$scope.mlsData.current.id}..."
          rmapsMlsService.getDatabaseList($scope.mlsData.current.id)
          .then (data) ->
            $scope.dbOptions = data
            $scope.formItems[1].disabled = false
            console.log "#### Step 0 processed"
            console.log "#### dbOptions:"
            console.log $scope.dbOptions

          .catch (err) ->
            # need to put in alert pane
            $scope.dbOptions = []
            $scope.tableOptions = []
            $scope.fieldOptions = []
            console.log "#### error step 0: #{err}"
        else
          return $q.when()

      disabled: false
      active: true
    ,
      step: 1
      heading: "Choose Database"
      process: () ->
        console.log "Processing step 1..."
        if $scope.tableOptions.length == 0 and $scope.mlsData.current.main_property_data.db
          console.log "populating tableOptions with db=#{$scope.mlsData.current.main_property_data.db}..."
          rmapsMlsService.getTableList($scope.mlsData.current.id, $scope.mlsData.current.main_property_data.db)
          .then (data) ->
            $scope.tableOptions = data
            $scope.formItems[2].disabled = false
            console.log "#### Step 1 processed"
            console.log "#### tableOptions:"
            console.log $scope.tableOptions

          .catch (err) ->
            $scope.tableOptions = []
            $scope.fieldOptions = []
            # need to put in alert pane
            console.log "#### error step 1: #{err}"
        else
          return $q.when()


      disabled: true
      active: false
    ,
      step: 2
      heading: "Choose Table"
      process: () ->
        console.log "Processing step 2..."
        # when going BACK to this step, only re-query if we have a table to use
        if $scope.mlsData.current.main_property_data.table
          console.log "populating fieldOptions with table=#{$scope.mlsData.current.main_property_data.table}..."
          rmapsMlsService.getColumnList($scope.mlsData.current.id, $scope.mlsData.current.main_property_data.db, $scope.mlsData.current.main_property_data.table)
          .then (data) ->
            r = /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
            $scope.fieldOptions = _.flatten([o for o in data when (_.some(k for k in _.keys(o) when typeof(k) == "string" && r.test(k.toLowerCase())) or _.some(v for v in _.values(o) when typeof(v) == "string" && r.test(v.toLowerCase())))], true)
            $scope.formItems[3].disabled = false
            console.log "#### Step 2 processed"
            console.log "#### fieldOptions:"
            console.log $scope.fieldOptions

          .catch (err) ->
            $scope.fieldOptions = []
            # need to put in alert pane
            console.log "#### error step 2: #{err}"
        else
          return $q.when()

      disabled: true
      active: false
    ,
      step: 3
      heading: "Choose Field"
      process: () ->
        $scope.mlsData.current.save()
        .then (res) ->
          console.log "#### Step 3 processed"
        .catch (err) ->
          console.log "#### Step 3 errored: #{err}"
      disabled: true
      active: false
    ]

    $scope.proceedTo = (toStep) ->
      console.log "#### trying to advance to step #{toStep}"
      thisStep = $scope.step

      # run proceed() of this step, which validates
      $scope.formItems[thisStep].process()
      .then () ->
        # incr active step if allowed
        if _.every($scope.formItems[..toStep], {disabled: false}) and toStep < ($scope.formItems.length)
          $scope.step = toStep
          console.log "Now on step #{$scope.step}"
          $scope.formItems[thisStep].active = false
          $scope.formItems[toStep].active = true

]


app.controller 'ModalInstanceCtrl', ['$scope', '$modalInstance', 'mlsModalData',
  ($scope, $modalInstance, mlsModalData) ->
    $scope.mlsModalData = mlsModalData;

    $scope.ok = () ->
      $modalInstance.close($scope.mlsModalData)

    $scope.cancel = () ->
      $modalInstance.dismiss('cancel')

]

