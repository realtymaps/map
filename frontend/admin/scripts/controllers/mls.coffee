_ = require 'lodash'
app = require '../app.coffee'
mlsConfigService = require '../services/mlsConfig.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
modalTemplate = require '../../html/views/templates/newMlsConfig.jade'

app.controller 'rmapsMlsCtrl', ['$rootScope', '$scope', '$location', '$state', 'rmapsMlsService', '$modal', 'Restangular', '$q', 'rmapsevents', 'mlsConstants', 'rmapsprincipal',
  ($rootScope, $scope, $location, $state, rmapsMlsService, $modal, Restangular, $q, rmapsevents, mlsConstants, rmapsprincipal) ->

    # init our dropdowns & mlsData
    $scope.loading = false
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
        main_property_data: {"queryTemplate": mlsConstants.queryTemplate}

    # keep track of readable names
    $scope.fieldNameMap =
      dbNames: {}
      tableNames: {}
      columnNames: {}

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

    # extract existing configs, populate idOptions
    # Register the logic that acquires data so it can be evaluated after auth
    $rootScope.registerScopeData () ->
      $scope.loading = true
      rmapsMlsService.getConfigs()
      .then (configs) ->
        $scope.idOptions = configs
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "Error in retrieving existing configs." }
      .finally () ->
        $scope.loading = false

    # when getting new mlsData, update the dropdowns as needed
    $scope.updateObjectOptions = (obj) ->
      $scope.loading = true
      deferred = $q.defer()
      promises = []
      getDbOptions()
      .then (dbData) ->
        getTableOptions()
        .then (tableData) ->
          getColumnOptions()
          .then (columnData) ->

      .then (results) ->
        $scope.proceed(1)
      .catch (err) ->
        msg = "Error in retrieving MLS data: #{err.message}"
        $rootScope.$emit rmapsevents.alert.spawn, { msg: msg }
        $q.reject(new Error(msg))
      .finally () ->
        $scope.loading = false

    # pull db options and enable next step as appropriate
    getDbOptions = () ->
      if $scope.mlsData.current.id
        rmapsMlsService.getDatabaseList($scope.mlsData.current.id)
        .then (data) ->
          $scope.dbOptions = data
          $scope.formItems[1].disabled = false
          $scope.fieldNameMap.dbNames = {}
          for datum in data
            $scope.fieldNameMap.dbNames[datum.ResourceID] = datum.VisibleName
          data
        .catch (err) ->
          $scope.dbOptions = []
          $scope.tableOptions = []
          $scope.columnOptions = []
          $scope.formItems[2].disabled = true
          $scope.formItems[3].disabled = true
          $q.reject(new Error("Error retrieving databases from MLS."))
      else
        $scope.dbOptions = []
        $scope.tableOptions = []
        $scope.columnOptions = []
        $scope.formItems[1].disabled = true
        $scope.formItems[2].disabled = true
        $scope.formItems[3].disabled = true
        return $q.when()

    # pull table options and enable next step as appropriate
    getTableOptions = () ->
      if $scope.mlsData.current.id and $scope.mlsData.current.main_property_data.db
        rmapsMlsService.getTableList($scope.mlsData.current.id, $scope.mlsData.current.main_property_data.db)
        .then (data) ->
          $scope.tableOptions = data
          $scope.formItems[2].disabled = false
          $scope.fieldNameMap.tableNames = {}
          for datum in data
            $scope.fieldNameMap.tableNames[datum.ClassName] = datum.VisibleName
          data
        .catch (err) ->
          $scope.tableOptions = []
          $scope.columnOptions = []
          $scope.formItems[2].disabled = true
          $scope.formItems[3].disabled = true
          $q.reject(new Error("Error retrieving tables from MLS."))
      else
        $scope.tableOptions = []
        $scope.columnOptions = []
        $scope.formItems[2].disabled = true
        $scope.formItems[3].disabled = true
        return $q.when()

    # pull column options and enable next step as appropriate
    getColumnOptions = () ->
      # when going BACK to this step, only re-query if we have a table to use
      if $scope.mlsData.current.id and $scope.mlsData.current.main_property_data.db and $scope.mlsData.current.main_property_data.table
        rmapsMlsService.getColumnList($scope.mlsData.current.id, $scope.mlsData.current.main_property_data.db, $scope.mlsData.current.main_property_data.table)
        .then (data) ->
          r = mlsConstants.dtColumnRegex
          $scope.columnOptions = _.flatten([o for o in data when (_.some(k for k in _.keys(o) when typeof(k) == "string" && r.test(k.toLowerCase())) or _.some(v for v in _.values(o) when typeof(v) == "string" && r.test(v.toLowerCase())))], true)
          $scope.formItems[3].disabled = false
          $scope.fieldNameMap.columnNames = {}
          for datum in data
            $scope.fieldNameMap.columnNames[datum.SystemName] = datum.LongName
          data
        .catch (err) ->
          $scope.columnOptions = []
          $q.reject(new Error("Error retrieving columns from MLS."))
      else
        $scope.columnOptions = []
        $scope.formItems[3].disabled = true
        return $q.when()

    # button behavior for saving mls
    $scope.saveMlsData = () ->
      $scope.loading = true
      rmapsMlsService.postMainPropertyData($scope.mlsData.current.id, $scope.mlsData.current.main_property_data)
      .then (res) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "#{$scope.mlsData.current.id} saved.", type: 'rm-success' }
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in saving configs.' }
      .finally () ->
        $scope.loading = false

    # call processAndProceed when on-change in dropdowns
    $scope.processAndProceed = (toStep) ->
      $scope.loading = true
      if $scope.step == 1 # db option just changed, reset table and fields
        $scope.tableOptions = []
        $scope.columnOptions = []
        $scope.mlsData.current.main_property_data.table = ""
        $scope.mlsData.current.main_property_data.field = ""
        $scope.formItems[2].disabled = true
        $scope.formItems[3].disabled = true
        promise = getTableOptions()

      else if $scope.step == 2 # table option just changed, reset table and fields
        $scope.columnOptions = []
        $scope.mlsData.current.main_property_data.field = ""
        $scope.formItems[3].disabled = true
        promise = getColumnOptions()

      else
        promise = $q.when()

      promise.then () ->
        $scope.proceed(toStep)
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in processing #{$scope.mlsData.current.id}.' }
      .finally () ->
        $scope.loading = false

    # switching basic step flags
    $scope.proceed = (toStep) ->
      $scope.formItems[$scope.step].active = false
      $scope.formItems[toStep].active = true
      $scope.step = toStep

    # goes to the 'normalize' state with selected mlsData
    $scope.goNormalize = () ->
      $state.go($state.get("normalize"), { id: $scope.mlsData.current.id }, { reload: true })

    # modal for Edit mlsData
    $scope.animationsEnabled = true
    $scope.openEdit = () ->
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
          $scope.loading = true
          $scope.mlsData.current.save()
          .then (res) ->
            $rootScope.$emit rmapsevents.alert.spawn, { msg: "#{$scope.mlsData.current.id} saved.", type: 'rm-success' }
          .catch (err) ->
            $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in saving configs.' }
          .finally () ->
            $scope.loading = false
        , () ->
          console.log "modal closed"
      )

    # modal for Create mlsData
    $scope.animationsEnabled = true
    $scope.openCreate = () ->
      modalInstance = $modal.open
        animation: $scope.animationsEnabled
        template: modalTemplate
        controller: 'ModalInstanceCtrl'
        resolve:
          mlsModalData: () ->
            return {
              id: null
              name: null
              notes: ""
              active: false
              username: null
              password: null
              url: null
              main_property_data: {"queryTemplate": mlsConstants.queryTemplate}
            }
      # ok/cancel behavior of modal
      modalInstance.result.then(
        (mlsModalData) ->
          rmapsMlsService.postConfig(mlsModalData, $scope.idOptions)
          .then (newMls) ->
            $scope.mlsData.current = newMls
            $scope.updateObjectOptions($scope.mlsData.current)
          .catch (err) ->
            msg = "Error saving MLS."
            $rootScope.$emit rmapsevents.alert.spawn, { msg: msg }
        , () ->
          console.log "modal closed"
      )

    #$rootScope.registerScopeState restoreState

]


app.controller 'ModalInstanceCtrl', ['$scope', '$modalInstance', 'mlsModalData', 'mlsConstants',
  ($scope, $modalInstance, mlsModalData, mlsConstants) ->
    $scope.mlsModalData = mlsModalData
    # state of editing if id is truthy
    $scope.editing = !!mlsModalData.id

    $scope.ok = () ->
      $modalInstance.close($scope.mlsModalData)

    $scope.cancel = () ->
      $modalInstance.dismiss('cancel')

]