_ = require 'lodash'
app = require '../app.coffee'
mlsConfigService = require '../services/mlsConfig.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
modalTemplate = require '../../html/views/templates/newMlsConfig.jade'

app.controller 'rmapsMlsCtrl', ['$rootScope', '$scope', '$state', 'rmapsMlsService', '$modal', 'Restangular', '$q', 'rmapsevents',
  ($rootScope, $scope, $state, rmapsMlsService, $modal, Restangular, $q, rmapsevents) ->

    # extract existing configs, populate idOptions
    rmapsMlsService.getConfigs()
    .then (configs) ->
      $scope.idOptions = configs
      console.log "#### configs:"
      console.log $scope.idOptions
    .catch (err) ->
      $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in retrieving existing configs.' }
      console.log "#### error getting configs:"
      console.log err

    # init our dropdowns & mlsData
    $scope.adminRoutes = adminRoutes
    $scope.$state = $state
    $scope.step = 0
    $scope.dbOptions = []
    $scope.tableOptions = []
    $scope.columnOptions = []
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

    # when leading new mlsData, update the dropdowns as needed
    $scope.updateObjectOptions = (obj) ->
      console.log "#### processing obj"
      console.log obj
      deferred = $q.defer()
      promises = []
      if obj.main_property_data.db
        promises.push getDbOptions()

        if obj.main_property_data.table
          promises.push getTableOptions()

          if obj.main_property_data.field
            promises.push getColumnOptions()
          else
            $scope.tableOptions = []
            $scope.formItems[3].disabled = true

        else
          $scope.tableOptions = []
          $scope.formItems[2].disabled = true

      else
        $scope.dbOptions = []
        $scope.formItems[1].disabled = true

      $q.all(promises)
      .then (results) ->
        console.log "#### results:"
        console.log results
        # hide wait icon

    # modal for create-new mlsData
    $scope.animationsEnabled = true
    $scope.open = () ->
      modalInstance = $modal.open
        animation: $scope.animationsEnabled
        template: modalTemplate
        controller: 'ModalInstanceCtrl'
        resolve:
          mlsModalData: () ->
            return $scope.mlsData.current

      # ok/cancel behavior of modal
      modalInstance.result.then(
        (mlsModalData) ->
          rmapsMlsService.postConfig(mlsModalData, $scope.idOptions)
          .then (newMls) ->
            $scope.mlsData.current = newMls
            $scope.updateObjectOptions(scope.mlsData.current)
          .catch (err) ->
            $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error saving MLS data.' }
            console.log "#### error saving MLS data:"
            console.log err
        , () ->
          console.log "modal closed"
      )

    # pull db options and enable next step as appropriate
    getDbOptions = () ->
      console.log "Getting db data..."
      if $scope.mlsData.current.id
        console.log "populating dbOptions with id=#{$scope.mlsData.current.id}..."
        rmapsMlsService.getDatabaseList($scope.mlsData.current.id)
        .then (data) ->
          $scope.dbOptions = data
          $scope.formItems[1].disabled = false
          console.log "#### dbOptions:"
          console.log $scope.dbOptions

        .catch (err) ->
          # need to put in alert pane
          $scope.dbOptions = []
          $scope.tableOptions = []
          $scope.columnOptions = []
          #$scope.formItems[1].disabled = false
          $scope.formItems[2].disabled = false
          $scope.formItems[3].disabled = false
          console.log "#### error getting dbOptions: #{err}"
      else
        return $q.when()

    # pull table options and enable next step as appropriate
    getTableOptions = () ->
      console.log "Getting table data..."
      if $scope.mlsData.current.id and $scope.mlsData.current.main_property_data.db
        console.log "populating tableOptions with db=#{$scope.mlsData.current.main_property_data.db}..."
        rmapsMlsService.getTableList($scope.mlsData.current.id, $scope.mlsData.current.main_property_data.db)
        .then (data) ->
          $scope.tableOptions = data
          $scope.formItems[2].disabled = false
          console.log "#### tableOptions:"
          console.log $scope.tableOptions

        .catch (err) ->
          $scope.tableOptions = []
          $scope.columnOptions = []
          #$scope.formItems[2].disabled = false
          $scope.formItems[3].disabled = false
          console.log "#### error getting tableOptions: #{err}"
      else
        return $q.when()

    # pull column options and enable next step as appropriate
    getColumnOptions = () ->
      console.log "Getting column data..."
      # when going BACK to this step, only re-query if we have a table to use
      if $scope.mlsData.current.id and $scope.mlsData.current.main_property_data.db and $scope.mlsData.current.main_property_data.table
        console.log "populating columnOptions with table=#{$scope.mlsData.current.main_property_data.table}..."
        rmapsMlsService.getColumnList($scope.mlsData.current.id, $scope.mlsData.current.main_property_data.db, $scope.mlsData.current.main_property_data.table)
        .then (data) ->
          r = /.*?date.*?|.*?time.*?|.*?modif.*?|.*?change.*?/
          $scope.columnOptions = _.flatten([o for o in data when (_.some(k for k in _.keys(o) when typeof(k) == "string" && r.test(k.toLowerCase())) or _.some(v for v in _.values(o) when typeof(v) == "string" && r.test(v.toLowerCase())))], true)
          $scope.formItems[3].disabled = false
          console.log "#### columnOptions:"
          console.log $scope.columnOptions

        .catch (err) ->
          $scope.columnOptions = []
          #$scope.formItems[3].disabled = false
          console.log "#### error getting columnOptions: #{err}"
      else
        return $q.when()

    # button behavior for saving mls
    saveMlsData = () ->
      $scope.mlsData.current.save()
      .then (res) ->
        console.log "#### Step 3 processed"
        # need to output "Saved" message
      .catch (err) ->
        console.log "#### Step 3 errored: #{err}"
        $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in saving configs.' }

    # tracking steps, active/disabled etc
    $scope.formItems = [
      step: 0
      heading: "Select MLS"
      disabled: false
      active: true
    ,
      step: 1
      heading: "Choose Database"
      disabled: true
      active: false
    ,
      step: 2
      heading: "Choose Table"
      disabled: true
      active: false
    ,
      step: 3
      heading: "Choose Field"
      disabled: true
      active: false
    ]

    # call processAndProceed when on-change in dropdowns
    $scope.processAndProceed = (toStep) ->
      console.log "#### processing before advancing to step #{toStep}"
      if $scope.step == 1 # db option just changed, reset table and fields
        $scope.tableOptions = []
        $scope.columnOptions = []
        $scope.mlsData.current.main_property_data.table = ""
        $scope.mlsData.current.main_property_data.field = ""
        $scope.formItems[2].disabled = true
        $scope.formItems[3].disabled = true
        promise = getTableOptions()

      else if $scope.step == 2 # db option just changed, reset table and fields
        $scope.columnOptions = []
        $scope.mlsData.current.main_property_data.field = ""
        $scope.formItems[3].disabled = true
        promise = getColumnOptions()

      else
        promise = $q.when()

      promise.then () ->
        $scope.proceed(toStep)
      .catch (err) ->
        console.log "#### error with proceeding:"
        console.log err

    # switching basic step flags
    $scope.proceed = (toStep) ->
      console.log "#### proceeding to step #{toStep}"
      $scope.formItems[$scope.step].active = false
      $scope.formItems[toStep].active = true
      $scope.step = toStep
      # hide loading icon

]


app.controller 'ModalInstanceCtrl', ['$scope', '$modalInstance', 'mlsModalData',
  ($scope, $modalInstance, mlsModalData) ->
    $scope.mlsModalData = mlsModalData;

    $scope.ok = () ->
      $modalInstance.close($scope.mlsModalData)

    $scope.cancel = () ->
      $modalInstance.dismiss('cancel')

]

