_ = require 'lodash'
app = require '../app.coffee'
mlsConfigService = require '../services/mlsConfig.coffee'
adminRoutes = require '../../../../common/config/routes.admin.coffee'
modalTemplate = require('../../html/views/templates/newMlsConfig.jade')()
changePasswordTemplate = require('../../html/views/templates/changePassword.jade')()

app.controller 'rmapsMlsCtrl', ['$rootScope', '$scope', '$location', '$state', '$timeout', 'rmapsMlsService', '$modal', 'Restangular', '$q', 'rmapsevents', 'mlsConstants', 'rmapsprincipal', 'rmapsJobsService'
  ($rootScope, $scope, $location, $state, $timeout, rmapsMlsService, $modal, Restangular, $q, rmapsevents, mlsConstants, rmapsprincipal, rmapsJobsService) ->

    # return new object with base defaults
    getDefaultBase = () ->
      obj = {}
      for key, value of mlsConstants.defaults.base
        obj[key] = value
      return obj

    restoreInitDbValueHack = () ->
      dropdown = angular.element(document.querySelector('#dbselect'))[0] # get the actual dropdown element
      options = dropdown.options # options list

      # only proceed with hack if 'selected' hasn't been registered (i.e. value='' and index=-1)
      if options.selectedIndex < 0
        # part of the bug here is that options.selectedIndex returns -1 even though an element has the selected property
        # note: the options here are all constructed involving typical ngmodel binding and ngoptions
        i = 0
        while options.item(i).getAttribute('label') isnt $scope.mlsData.current.main_property_data.db and i < options.length
          i += 1 # go through items to see which has correct label

        if i > 1 and i < options.length # ensure index is valid bound
          dbIndex = i - 1 # identifier corresponds to index of selected item, minus 1 to accout for blank element
          dropdown.value = dbIndex # forceably assign the value (for some reason this is what is not occuring upon refresh)

    nonBaseDefaults = _.assign {}, mlsConstants.defaults.otherConfig, _.clone mlsConstants.defaults.propertySchema

    # init our dropdowns & mlsData
    $scope.loading = false
    $scope.adminRoutes = adminRoutes
    $scope.$state = $state
    $scope.step = 0
    $scope.dbOptions = []
    $scope.tableOptions = []
    $scope.columnOptions = []
    $scope.allowPasswordReset = false
    $scope.mlsData =
      current: getDefaultBase()
      propertySchemaDefaults: mlsConstants.defaults.propertySchema
      configDefaults: mlsConstants.defaults.otherConfig
      task: mlsConstants.defaults.task

    # keep track of readable names
    $scope.fieldNameMap =
      dbNames: {}
      tableNames: {}
      columnNames: {}

    # simple tracking for main_property_data dropdowns
    $scope.formItems = [
      disabled: false
    ,
      disabled: true
    ,
      disabled: true
    ,
      disabled: true
    ]

    # extract existing configs, populate idOptions
    # Register the logic that acquires data so it can be evaluated after auth
    $rootScope.registerScopeData () ->
      $scope.loading = true
      rmapsMlsService.getConfigs()
      .then (configs) ->
        for config in configs
          config.ready = if $scope.isReady(config) then 'ready' else 'incomplete'
        $scope.idOptions = configs
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in retrieving existing configs.' }
      .finally () ->
        $scope.loading = false

    $scope.activatePasswordButton = () ->
      $scope.allowPasswordReset = true
      $scope.mlsData.current.password = ''

    $scope.assignConfigDefault = (obj, field) ->
      if typeof nonBaseDefaults[field] is 'object'
        obj[field] = _.clone nonBaseDefaults[field]
      else
        obj[field] = nonBaseDefaults[field]

    # this assigns any 'undefined' to default value, and empty strings to null
    # null is being considered valid option
    $scope.cleanConfigValues = (obj) ->
      for key, value of nonBaseDefaults
        if (typeof obj[key] is 'undefined') # null can be valid
          $scope.assignConfigDefault(obj, key)
        else if value is ''
          obj[key] = null

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
            rmapsJobsService.getTask($scope.mlsData.current.id)
            .then (task) ->
              $scope.mlsData.task.active = if task.length > 0 and task[0].active? then task[0].active else false

      .then (results) ->
        # populate undefined fields with the defaults
        $scope.cleanConfigValues(obj)
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
        .then (rawData) ->
          data = ({ObjectVersion: x.ObjectVersion, ResourceID: x.ResourceID, StandardName: x.StandardName, VisibleName: x.VisibleName} for x in rawData)
          $scope.dbOptions = data
          $scope.formItems[1].disabled = false
          $scope.fieldNameMap.dbNames = {}
          for datum in data
            $scope.fieldNameMap.dbNames[datum.ResourceID] = datum.VisibleName
          $timeout () ->
            restoreInitDbValueHack()
          data
        .catch (err) ->
          $scope.dbOptions = []
          $scope.tableOptions = []
          $scope.columnOptions = []
          $scope.formItems[2].disabled = true
          $scope.formItems[3].disabled = true
          $q.reject(new Error('Error retrieving databases from MLS.'))
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
        .then (rawData) ->
          data = ({ClassName: x.ClassName, StandardName: x.StandardName, VisibleName: x.VisibleName} for x in rawData)
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
          $q.reject(new Error('Error retrieving tables from MLS.'))
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
        .then (rawData) ->
          data = ({SystemName: x.SystemName, LongName: x.LongName, DataType: x.DataType} for x in rawData)
          r = mlsConstants.dtColumnRegex
          $scope.columnOptions = _.flatten([o for o in data when (_.some(k for k in _.keys(o) when typeof(k) == 'string' && r.test(k.toLowerCase())) or _.some(v for v in _.values(o) when typeof(v) == 'string' && r.test(v.toLowerCase())))], true)
          $scope.formItems[3].disabled = false
          $scope.fieldNameMap.columnNames = {}
          for datum in data
            $scope.fieldNameMap.columnNames[datum.SystemName] = datum.LongName
          data
        .catch (err) ->
          $scope.columnOptions = []
          $q.reject(new Error('Error retrieving columns from MLS.'))
      else
        $scope.columnOptions = []
        $scope.formItems[3].disabled = true
        return $q.when()

    $scope.saveServerData = () ->
      $scope.loading = true
      rmapsMlsService.postServerData($scope.mlsData.current.id, { url: $scope.mlsData.current.url, username: $scope.mlsData.current.username })
      .then (res) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "#{$scope.mlsData.current.id} server data saved.", type: 'rm-success' }
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in saving server data.' }
      .finally () ->
        $scope.loading = false

    $scope.saveServerPassword = () ->
      $scope.loading = true
      rmapsMlsService.postServerPassword($scope.mlsData.current.id, { password: $scope.mlsData.current.password })
      .then (res) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "#{$scope.mlsData.current.id} server password saved.", type: 'rm-success' }
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in saving server password.' }
      .finally () ->
        $scope.allowPasswordReset = false
        $scope.loading = false

    $scope.saveMlsConfigData = () ->
      $scope.loading = true
      promises = []
      $scope.cleanConfigValues($scope.mlsData.current)

      promises.push rmapsJobsService.updateTask($scope.mlsData.current.id, {active: $scope.mlsData.task.active})
      promises.push $scope.mlsData.current.save()

      if rmapsprincipal.hasPermission('change_mlsconfig_serverdata')
        promises.push rmapsMlsService.postServerData($scope.mlsData.current.id, { url: $scope.mlsData.current.url, username: $scope.mlsData.current.username })

      $q.all(promises)
      .then (res) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "#{$scope.mlsData.current.id} saved.", type: 'rm-success' }
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: 'Error in saving mls config.' }
      .finally () ->
        $scope.loading = false

    # call processAndProceed when on-change in dropdowns
    $scope.processAndProceed = (toStep) ->
      $scope.loading = true
      if toStep == 1 # db option just changed, reset table and fields
        $scope.tableOptions = []
        $scope.columnOptions = []
        $scope.mlsData.current.main_property_data.table = ''
        $scope.mlsData.current.main_property_data.field = ''
        $scope.formItems[2].disabled = true
        $scope.formItems[3].disabled = true
        promise = getTableOptions()

      else if toStep == 2 # table option just changed, reset table and fields
        $scope.columnOptions = []
        $scope.mlsData.current.main_property_data.field = ''
        $scope.formItems[3].disabled = true
        promise = getColumnOptions()

      else
        promise = $q.when()

      promise.then()
      .catch (err) ->
        $rootScope.$emit rmapsevents.alert.spawn, { msg: "Error in processing #{$scope.mlsData.current.id}." }
      .finally () ->
        $scope.loading = false

    # goes to the 'normalize' state with selected mlsData
    $scope.goNormalize = () ->
      $state.go($state.get('normalize'), { id: $scope.mlsData.current.id }, { reload: true })

    # test for whether all default values being used or not
    $scope.hasAllDefaultOtherConfig = () ->
      _.every(_.keys(mlsConstants.defaults.otherConfig), (k) ->
        # null is a valid field value
        return (typeof $scope.mlsData.current[k] is 'undefined' or $scope.mlsData.current[k] is mlsConstants.defaults.otherConfig[k])
      )

    # test for whether MLS is ready and eligible for task activation and normalization
    $scope.isReady = (mlsObj) ->
      _.every ['queryTemplate', 'db', 'table', 'field'], (k) ->
        return mlsObj.main_property_data? and k of mlsObj.main_property_data and mlsObj.main_property_data[k] != ''

    # modal for Create mlsData
    $scope.animationsEnabled = true
    $scope.openCreate = () ->
      modalInstance = $modal.open
        animation: $scope.animationsEnabled
        template: modalTemplate
        controller: 'ModalInstanceCtrl'
        resolve:
          mlsModalData: () ->
            return getDefaultBase()
      # ok/cancel behavior of modal
      modalInstance.result.then(
        (mlsModalData) ->
          $scope.cleanConfigValues(mlsModalData)
          rmapsMlsService.postConfig(mlsModalData, $scope.idOptions)
          .then (newMls) ->
            $scope.mlsData.current = newMls
            $scope.updateObjectOptions($scope.mlsData.current)
          .catch (err) ->
            msg = 'Error saving MLS.'
            $rootScope.$emit rmapsevents.alert.spawn, { msg: msg }
        , () ->
          console.log 'modal closed'
      )

    $scope.passwordModal = () ->
      modalInstance = $modal.open
        animation: $scope.animationsEnabled
        template: changePasswordTemplate
        controller: 'ModalPasswordCtrl'

      # ok/cancel behavior of modal
      modalInstance.result.then(
        (password) ->
          $scope.mlsData.current.password = password
          $scope.saveServerPassword()
        , () ->
          console.log 'password modal closed'
      )
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

app.controller 'ModalPasswordCtrl', ['$scope', '$modalInstance'
  ($scope, $modalInstance) ->
    $scope.newpassword = ''

    $scope.ok = () ->
      $modalInstance.close($scope.newpassword)

    $scope.cancel = () ->
      $modalInstance.dismiss('cancel')

]
