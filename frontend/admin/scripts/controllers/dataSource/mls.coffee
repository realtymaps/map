###globals angular###
_ = require 'lodash'
app = require '../../app.coffee'

adminRoutes = require '../../../../../common/config/routes.admin.coffee'
modalTemplate = require('../../../html/views/templates/newMlsConfig.jade')()
selectIconTemplate = require('../../../html/views/templates/selectIcon.jade')()
changePasswordTemplate = require('../../../html/views/templates/changePassword.jade')()

app.controller 'rmapsMlsCtrl',
  ($rootScope, $scope, $location, $state, $timeout, $uibModal, $q,
  rmapsMlsService,
  rmapsEventConstants,
  rmapsAdminConstants,
  rmapsPrincipalService,
  rmapsJobsService) ->

    # return new object with base defaults
    getDefaultBase = () ->
      obj = {}
      for key, value of rmapsAdminConstants.defaults.base
        obj[key] = value
      return obj

    restoreInitDbValueHack = (schema) ->
      dropdown = angular.element(document.querySelector('#dbselect'))[0] # get the actual dropdown element
      options = dropdown.options # options list

      # only proceed with hack if 'selected' hasn't been registered (i.e. value='' and index=-1)
      if options.selectedIndex < 0
        # part of the bug here is that options.selectedIndex returns -1 even though an element has the selected property
        # note: the options here are all constructed involving typical ngmodel binding and ngoptions
        i = 0
        while options.item(i).getAttribute('label') isnt $scope.mlsData.current[schema].db and i < options.length
          i += 1 # go through items to see which has correct label

        if i > 1 and i < options.length # ensure index is valid bound
          dbIndex = i - 1 # identifier corresponds to index of selected item, minus 1 to accout for blank element
          dropdown.value = dbIndex # forceably assign the value (for some reason this is what is not occuring upon refresh)

    nonBaseDefaults = _.assign {}, rmapsAdminConstants.defaults.otherConfig, _.clone rmapsAdminConstants.defaults.propertySchema, _.clone rmapsAdminConstants.defaults.agentSchema

    # init our dropdowns & mlsData
    $scope.loading = false
    $scope.adminRoutes = adminRoutes
    $scope.$state = $state
    $scope.step = 0
    $scope.schemaOptions =
      listing_data:
        db: []
        table: []
        column: []
      agent_data:
        db: []
        table: []
        column: []

    $scope.allowPasswordReset = false
    $scope.mlsData =
      current: getDefaultBase()
      propertySchemaDefaults: rmapsAdminConstants.defaults.propertySchema
      agentSchemaDefaults: rmapsAdminConstants.defaults.agentSchema
      configDefaults: rmapsAdminConstants.defaults.otherConfig
      task: rmapsAdminConstants.defaults.task
    $scope.ui = rmapsAdminConstants.ui

    # keep track of readable names
    $scope.fieldNameMap =
      listing_data:
        dbNames: {}
        tableNames: {}
        columnNames: {}
        columnTypes: {}
        # objects: {}
      agent_data:
        dbNames: {}
        tableNames: {}
        columnNames: {}
        columnTypes: {}
      objects: {}

    # simple tracking for listing_data dropdowns
    $scope.formItems =
      listing_data: [
          disabled: false
        ,
          disabled: true
        ,
          disabled: true
        ,
          disabled: true
        ],
      agent_data: [
          disabled: false
        ,
          disabled: true
        ,
          disabled: true
        ,
          disabled: true
        ]


    # extract existing configs, populate idOptions
    $scope.loading = true
    rmapsMlsService.getConfigs()
    .then (configs) ->
      for config in configs
        config.ready = if $scope.isReady(config) then 'ready' else 'incomplete'
      $scope.idOptions = configs
    .catch (err) ->
      $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: 'Error in retrieving existing configs.' }
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

    $scope.testOverlapSettings = (obj) ->
      rmapsMlsService.testOverlapSettings(obj.id)

    # when getting new mlsData, update the dropdowns as needed
    $scope.updateObjectOptions = (obj) ->
      $scope.loading = true

      #NOTE: must be sequential to not have multiple logins for MRED?
      _.reduce [
          getDbOptions
          getTableOptions
          getColumnOptions
          getObjectOptions
      ], (res, promise) ->
        if !res.then?
          res = res('listing_data')
        res.then () -> promise('listing_data')
      .then () ->
        _.reduce [
            getDbOptions
            getTableOptions
            getColumnOptions
            getObjectOptions
        ], (res, promise) ->
          if !res.then?
            res = res('agent_data')
          res.then () -> promise('agent_data')

      .then () ->
        rmapsJobsService.getTask($scope.mlsData.current.id+'_listing')
      .then (task) ->
        $scope.mlsData.task.active = if task.length > 0 and task[0].active? then task[0].active else false

      .then (results) ->
        # populate undefined fields with the defaults
        $scope.cleanConfigValues(obj)
      .catch (err) ->
        msg = "Error in retrieving MLS data: #{err.message}"
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: msg }
        $q.reject(new Error(msg))
      .finally () ->
        $scope.loading = false

    getObjectOptions = (schema) ->
      rmapsMlsService.getObjectList($scope.mlsData.current.id)
      .then (data) ->
        $scope.fieldNameMap.objects = data.map (v) -> v.VisibleName

    # pull db options and enable next step as appropriate
    getDbOptions = (schema) ->
      if $scope.mlsData.current.id
        rmapsMlsService.getDatabaseList($scope.mlsData.current.id)
        .then (rawData) ->
          data = ({ObjectVersion: x.ObjectVersion, ResourceID: x.ResourceID, StandardName: x.StandardName, VisibleName: x.VisibleName} for x in rawData)
          $scope.schemaOptions[schema].db = data
          $scope.formItems[schema][1].disabled = false
          $scope.fieldNameMap[schema].dbNames = {}
          for datum in data
            $scope.fieldNameMap[schema].dbNames[datum.ResourceID] = datum.VisibleName
          $timeout () ->
            restoreInitDbValueHack()
          data
        .catch () ->
          $scope.schemaOptions[schema].db = []
          $scope.schemaOptions[schema].table = []
          $scope.schemaOptions[schema].column = []
          $scope.formItems[schema][2].disabled = true if $scope.formItems[schema].length > 2
          $scope.formItems[schema][3].disabled = true if $scope.formItems[schema].length > 3
          $q.reject(new Error('Error retrieving databases from MLS.'))
      else
        $scope.schemaOptions[schema].db = []
        $scope.schemaOptions[schema].table = []
        $scope.schemaOptions[schema].column = []
        $scope.formItems[schema][1].disabled = true if $scope.formItems[schema].length > 1
        $scope.formItems[schema][2].disabled = true if $scope.formItems[schema].length > 2
        $scope.formItems[schema][3].disabled = true if $scope.formItems[schema].length > 3
        return $q.when()

    # pull table options and enable next step as appropriate
    getTableOptions = (schema) ->
      if $scope.mlsData.current.id and $scope.mlsData.current[schema].db
        rmapsMlsService.getTableList($scope.mlsData.current.id, $scope.mlsData.current[schema].db)
        .then (rawData) ->
          data = ({ClassName: x.ClassName, StandardName: x.StandardName, VisibleName: x.VisibleName} for x in rawData)
          $scope.schemaOptions[schema].table = data
          $scope.formItems[schema][2].disabled = false if $scope.formItems[schema].length > 2
          $scope.fieldNameMap[schema].table = {}
          for datum in data
            $scope.fieldNameMap[schema].tableNames[datum.ClassName] = datum.VisibleName
          data
        .catch () ->
          $scope.schemaOptions[schema].table = []
          $scope.schemaOptions[schema].column = []
          $scope.formItems[schema][2].disabled = true if $scope.formItems[schema].length > 2
          $scope.formItems[schema][3].disabled = true if $scope.formItems[schema].length > 3
          $q.reject(new Error('Error retrieving tables from MLS.'))
      else
        $scope.schemaOptions[schema].table = []
        $scope.schemaOptions[schema].column = []
        $scope.formItems[schema][2].disabled = true if $scope.formItems[schema].length > 2
        $scope.formItems[schema][3].disabled = true if $scope.formItems[schema].length > 3
        return $q.when()

    # pull column options and enable next step as appropriate
    getColumnOptions = (schema) ->
      # when going BACK to this step, only re-query if we have a table to use
      if $scope.mlsData.current.id and $scope.mlsData.current[schema].db and $scope.mlsData.current[schema].table
        rmapsMlsService.getColumnList($scope.mlsData.current.id, $scope.mlsData.current[schema].db, $scope.mlsData.current[schema].table)
        .then (rawData) ->
          data = ({SystemName: x.SystemName, LongName: x.LongName, DataType: x.DataType} for x in rawData)
          r = rmapsAdminConstants.dtColumnRegex
          $scope.schemaOptions[schema].column = _.flatten(
            [o for o in data when (_.some(k for k in _.keys(o) when typeof(k) == 'string' && r.test(k.toLowerCase())) or _.some(v for v in _.values(o) when typeof(v) == 'string' && r.test(v.toLowerCase())))
            ], true)
          $scope.formItems[schema][3].disabled = false if $scope.formItems[schema].length > 3
          $scope.fieldNameMap[schema].columnNames = {}
          $scope.fieldNameMap[schema].columnTypes = {}
          for datum in data
            $scope.fieldNameMap[schema].columnNames[datum.SystemName] = datum.LongName
            $scope.fieldNameMap[schema].columnTypes[datum.SystemName] = datum.DataType
          data
        .catch () ->
          $scope.schemaOptions[schema].column
          $q.reject(new Error('Error retrieving columns from MLS.'))
      else
        $scope.schemaOptions[schema].column
        $scope.formItems[schema][3].disabled = true if $scope.formItems[schema].length > 3
        return $q.when()

    $scope.saveServerData = () ->
      $scope.loading = true
      rmapsMlsService.postServerData($scope.mlsData.current.id, { url: $scope.mlsData.current.url, username: $scope.mlsData.current.username })
      .then (res) ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: "#{$scope.mlsData.current.id} server data saved.", type: 'rm-success' }
      .catch () ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: 'Error in saving server data.' }
      .finally () ->
        $scope.loading = false

    $scope.saveServerPassword = () ->
      $scope.loading = true
      rmapsMlsService.postServerPassword($scope.mlsData.current.id, { password: $scope.mlsData.current.password })
      .then (res) ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: "#{$scope.mlsData.current.id} server password saved.", type: 'rm-success' }
      .catch () ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: 'Error in saving server password.' }
      .finally () ->
        $scope.allowPasswordReset = false
        $scope.loading = false

    $scope.saveMlsConfigData = () ->
      $scope.loading = true
      promises = []
      $scope.cleanConfigValues($scope.mlsData.current)
      promises.push rmapsJobsService.updateTask("#{$scope.mlsData.current.id}_listing", {active: $scope.mlsData.task.active})
      promises.push rmapsJobsService.updateTask("#{$scope.mlsData.current.id}_agent", {active: $scope.mlsData.task.active})
      promises.push rmapsJobsService.updateTask("#{$scope.mlsData.current.id}_photo", {active: $scope.mlsData.task.active})
      promises.push $scope.mlsData.current.save()

      if rmapsPrincipalService.hasPermission('change_mlsconfig_serverdata')
        promises.push rmapsMlsService.postServerData($scope.mlsData.current.id, { url: $scope.mlsData.current.url, username: $scope.mlsData.current.username })

      $q.all(promises)
      .then (res) ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: "#{$scope.mlsData.current.id} saved.", type: 'rm-success' }
      .catch (err) ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: 'Error in saving mls config.' }
      .finally () ->
        $scope.loading = false

    # call processAndProceed when on-change in dropdowns
    $scope.processAndProceed = (toStep, schema) ->
      $scope.loading = true
      if toStep == 1 # db option just changed, reset table and fields
        $scope.schemaOptions[schema].table = []
        $scope.schemaOptions[schema].column = []
        $scope.mlsData.current[schema].table = ''
        $scope.mlsData.current[schema].field = ''
        $scope.mlsData.current[schema].field_type = ''
        $scope.formItems[schema][2].disabled = true if $scope.formItems[schema].length > 2
        $scope.formItems[schema][3].disabled = true if $scope.formItems[schema].length > 3
        promise = getTableOptions(schema)

      else if toStep == 2 # table option just changed, reset table and fields
        $scope.schemaOptions[schema].column = []
        $scope.mlsData.current[schema].field = ''
        $scope.mlsData.current[schema].field_type = ''
        $scope.formItems[schema][3].disabled = true if $scope.formItems[schema].length > 3
        promise = getColumnOptions(schema)

      else
        promise = $q.when()

      promise.then()
      .catch (err) ->
        $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: "Error in processing #{$scope.mlsData.current.id}." }
      .finally () ->
        $scope.loading = false

    # goes to the 'normalize' state with selected mlsData
    $scope.goNormalize = () ->
      $state.go($state.get('normalize'), { id: $scope.mlsData.current.id }, { reload: true })

    # test for whether all default values being used or not
    $scope.hasAllDefaultOtherConfig = () ->
      _.every(_.keys(rmapsAdminConstants.defaults.otherConfig), (k) ->
        return ($scope.mlsData.current[k] == rmapsAdminConstants.defaults.otherConfig[k])
      )

    # test for whether MLS is ready and eligible for task activation and normalization
    $scope.isReady = (mlsObj) ->
      _.every ['db', 'table', 'field'], (k) ->
        listing_data_truth = (mlsObj.listing_data? and k of mlsObj.listing_data and mlsObj.listing_data[k] != '')
        agent_data_truth = (mlsObj.agent_data? and k of mlsObj.agent_data and mlsObj.agent_data[k] != '')
        return listing_data_truth && agent_data_truth

    # modal for Create mlsData
    $scope.animationsEnabled = true
    $scope.openCreate = () ->
      modalInstance = $uibModal.open
        animation: $scope.animationsEnabled
        template: modalTemplate
        controller: 'rmapsModalCreateCtrl'
        resolve:
          mlsModalData: () ->
            return getDefaultBase()

      # ok/cancel behavior of modal
      modalInstance.result.then (mlsModalData) ->
        $scope.cleanConfigValues(mlsModalData)
        rmapsMlsService.postConfig(mlsModalData, $scope.idOptions)
        .then (newMls) ->
          $scope.mlsData.current = newMls
          $scope.updateObjectOptions($scope.mlsData.current)
        .catch (err) ->
          msg = 'Error saving MLS.'
          $rootScope.$emit rmapsEventConstants.alert.spawn, { msg: msg }

    $scope.selectIcon = () ->
      modalInstance = $uibModal.open
        animation: $scope.animationsEnabled
        template: selectIconTemplate
        controller: 'rmapsModalLogoCtrl'
        resolve:
          mlsModalData: () ->
            return $scope.mlsData.current

    $scope.passwordModal = () ->
      modalInstance = $uibModal.open
        animation: $scope.animationsEnabled
        template: changePasswordTemplate
        controller: 'rmapsModalPasswordCtrl'

      # ok/cancel behavior of modal
      modalInstance.result.then (password) ->
        $scope.mlsData.current.password = password
        $scope.saveServerPassword()

app.controller 'rmapsModalCreateCtrl',
  ($scope, $uibModalInstance, mlsModalData, rmapsAdminConstants) ->
    $scope.mlsModalData = mlsModalData
    # state of editing if id is truthy
    $scope.editing = !!mlsModalData.id

    $scope.ok = () ->
      $uibModalInstance.close($scope.mlsModalData)

    $scope.cancel = () ->
      $uibModalInstance.dismiss('cancel')


app.controller 'rmapsModalLogoCtrl',
  ($scope, $uibModalInstance, mlsModalData, rmapsAdminConstants, rmapsMainOptions) ->
    $scope.iconList = rmapsMainOptions.mlsicons.filelist
    $scope.mlsModalData = mlsModalData

    $scope.selectIcon = (logo) ->
      $scope.mlsModalData.disclaimer_logo = logo

    $scope.ok = () ->
      $uibModalInstance.close($scope.mlsModalData)

    $scope.cancel = () ->
      $scope.mlsModalData.disclaimer_logo = null
      $uibModalInstance.dismiss('cancel')


app.controller 'rmapsModalPasswordCtrl',
  ($scope, $uibModalInstance) ->
    $scope.newpassword = ''

    $scope.ok = () ->
      $uibModalInstance.close($scope.newpassword)

    $scope.cancel = () ->
      $uibModalInstance.dismiss('cancel')
