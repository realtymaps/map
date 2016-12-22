###globals angular###
_ = require 'lodash'
app = require '../../app.coffee'

adminRoutes = require '../../../../../common/config/routes.admin.coffee'
modalTemplate = require('../../../html/views/templates/newMlsConfig.jade')()
selectIconTemplate = require('../../../html/views/templates/selectIcon.jade')()
changePasswordTemplate = require('../../../html/views/templates/changePassword.jade')()


app.controller 'rmapsMlsCtrl',
  ($rootScope, $scope, $location, $state, $timeout, $uibModal, $q, $log,
  rmapsMlsService,
  rmapsEventConstants,
  rmapsAdminConstants,
  rmapsPrincipalService,
  rmapsJobsService,
  rmapsCleanData
  rmapsPhotoHelper) ->

    # return new object with base defaults
    getDefaultBase = () ->
      obj = {}
      for key, value of rmapsAdminConstants.defaults.base
        obj[key] = value
      return obj


    initPhotoSchemaOptions = () ->
      objects:
        use: false
        change: () ->
          if !@use
            delete $scope.mlsData.current.listing_data.photoObjects
            getObjectOptions('listing_data')
      info:
        editing: false
        temp: ''
        edit:() ->
          @temp = '' + $scope.mlsData.current.listing_data.photoInfo
          $scope.schemaOptions.listing_data.photos.info.editing = true

        save:() ->
          $scope.mlsData.current.listing_data.photoInfo = @temp
          @temp = ''
          @editing = false

        cancel: () ->
          @temp = ''
          @editing = false

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
    $scope.schemaOptions = _.merge {}, rmapsAdminConstants.defaults.schemaOptions,
      listing_data:
        photos:
          initPhotoSchemaOptions()


    $scope.allowPasswordReset = false
    $scope.mlsData =
      current: getDefaultBase()
      propertySchemaDefaults: rmapsAdminConstants.defaults.propertySchema
      agentSchemaDefaults: rmapsAdminConstants.defaults.agentSchema
      configDefaults: rmapsAdminConstants.defaults.otherConfig
      task: rmapsAdminConstants.defaults.task
    $scope.ui = rmapsAdminConstants.ui

    # keep track of readable names
    $scope.fieldNameMap = _.clone rmapsAdminConstants.defaults.fieldNameMap


    # simple tracking for listing_data dropdowns
    $scope.formItems = _.clone rmapsAdminConstants.defaults.formItems

    $scope.columns = _.clone rmapsAdminConstants.defaults.columns

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
    # NOTE MAIN ENTRY from mls.jade where (scope.mlsData.current = whatever) was set by ng-model
    $scope.updateObjectOptions = (obj) ->
      $scope.loading = true

      #NOTE: must be sequential to not have multiple logins for MRED?
      $q.each [ getDbOptions, getTableOptions, getColumnOptions, getObjectOptions], (fn) ->
        fn('listing_data')
      .then () ->
        $q.each [ getDbOptions, getTableOptions, getColumnOptions, getObjectOptions], (fn) ->
          fn('agent_data')
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

    ###
      Area to fix the formatting of $scope.mlsData.current prior to saving

      Some fields that are defined a certain way should be deleted.
    ###
    formatOnSave = () ->
      if _.isString $scope.mlsData.current.listing_data.photoObjects
        if !$scope.mlsData.current.listing_data.photoObjects
          delete $scope.mlsData.current.listing_data.photoObjects
        else
          $scope.mlsData.current.listing_data.photoObjects = $scope.mlsData.current.listing_data.photoObjects.trimAll().split(',')

      if $scope.mlsData.current.listing_data.Location == 0
        delete $scope.mlsData.current.listing_data.Location


    getObjectOptions = (schema) ->

      rmapsMlsService.getObjectList($scope.mlsData.current.id)
      .then (data) ->

        if schema == 'listing_data'
          if !$scope.mlsData.current.listing_data.Location?
            $scope.mlsData.current.listing_data.Location = 0

          if $scope.mlsData.current.listing_data.photoObjects?.length
            $scope.schemaOptions.listing_data.photos.objects.use = true
            return

        $scope.fieldNameMap.objects = data.map (v) -> v.VisibleName

    updateFormItems = ({schema, state, doDb, doTable}) ->
      doTable ?= true
      doDb ?= false

      if doTable && $scope.formItems[schema].table?
        $scope.formItems[schema].table.disabled = state
      if doDb && $scope.formItems[schema].table?
        $scope.formItems[schema].table.disabled = state

      # coffeelint: disable=check_scope
      for column, longName of $scope.columns[schema]
      # coffeelint: enable=check_scope
        if $scope.formItems[schema].lastModTime?
          $scope.formItems[schema][column].disabled = state

    cleanCurrentColumns = (schema) ->
      # coffeelint: disable=check_scope
      for column, longName of $scope.columns[schema]
      # coffeelint: enable=check_scope
        if $scope.formItems[schema].lastModTime?
          $scope.mlsData.current[schema][column] = rmapsCleanData()

    # pull db options and enable next step as appropriate
    getDbOptions = (schema) ->
      if $scope.mlsData.current.id
        rmapsMlsService.getDatabaseList($scope.mlsData.current.id)
        .then (rawData) ->
          data = ({ObjectVersion: x.ObjectVersion, ResourceID: x.ResourceID, StandardName: x.StandardName, VisibleName: x.VisibleName} for x in rawData)
          $scope.schemaOptions[schema].db = data
          $scope.formItems[schema].db.disabled = false
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
          updateFormItems({schema, state:true})
          $q.reject(new Error('Error retrieving databases from MLS.'))
      else
        $scope.schemaOptions[schema].db = []
        $scope.schemaOptions[schema].table = []
        $scope.schemaOptions[schema].column = []
        updateFormItems({schema, state:true, doDb:true})
        return $q.when()

    # pull table options and enable next step as appropriate
    getTableOptions = (schema) ->
      if $scope.mlsData.current.id and $scope.mlsData.current[schema].db
        rmapsMlsService.getTableList($scope.mlsData.current.id, $scope.mlsData.current[schema].db)
        .then (rawData) ->
          data = ({ClassName: x.ClassName, StandardName: x.StandardName, VisibleName: x.VisibleName} for x in rawData)
          $scope.schemaOptions[schema].table = data
          $scope.formItems[schema].table.disabled = false if $scope.formItems[schema].table?
          $scope.fieldNameMap[schema].table = {}
          for datum in data
            $scope.fieldNameMap[schema].tableNames[datum.ClassName] = datum.VisibleName
          data
        .catch () ->
          $scope.schemaOptions[schema].table = []
          $scope.schemaOptions[schema].column = []
          updateFormItems({schema, state:true})
          $q.reject(new Error('Error retrieving tables from MLS.'))
      else
        $scope.schemaOptions[schema].table = []
        $scope.schemaOptions[schema].column = []
        updateFormItems({schema, state:true})
        return $q.when()

    # pull column options and enable next step as appropriate
    getColumnOptions = (schema) ->
      # when going BACK to this step, only re-query if we have a table to use
      if $scope.mlsData.current.id && $scope.mlsData.current[schema].db && $scope.mlsData.current[schema].table
        rmapsMlsService.getColumnList(
          $scope.mlsData.current.id, $scope.mlsData.current[schema].db,
          $scope.mlsData.current[schema].table)
        .then (rawData) ->
          makeError = (thing) ->
            err = new Error "#{thing}: schema: #{schema}, column: #{column} UNDEFINED"
            $log.error(err)
            throw err

          for column, longName of $scope.columns[schema]
            $log.debug -> "column: #{column}, longName: #{longName}"
            regex = rmapsAdminConstants.defaults.columnRegExes[column]

            if !regex?
              makeError("regex")

            if !$scope.formItems[schema]?[column]?
              makeError("formItems")

            if !$scope.fieldNameMap[schema]?[column]?
              makeError("fieldNameMap")

            data = ({SystemName: x.SystemName, LongName: x.LongName, DataType: x.DataType} for x in rawData)

            $scope.schemaOptions[schema].columns[column] = {}
            $scope.schemaOptions[schema].columns[column].options = _.flatten(
              # ok props to whomever made this; (your smart) now what the heck does it do?
              # guess flattens / keeps objects where the k or v are a string and they match the regex
              [o for o in data when (_.some(k for k in _.keys(o) when _.isString(k) && regex.test(k.toLowerCase())) or _.some(v for v in _.values(o) when _.isString(v) && regex.test(v.toLowerCase())))
              ], true)
            $scope.formItems[schema][column].disabled = false if $scope.formItems[schema][column]?
            $scope.fieldNameMap[schema][column].columnNames = {}
            $scope.fieldNameMap[schema][column].columnTypes = {}
            for datum in data
              $scope.fieldNameMap[schema][column].columnNames[datum.SystemName] = datum.LongName
              $scope.fieldNameMap[schema][column].columnTypes[datum.SystemName] = datum.DataType
            data
        .catch () ->
          $q.reject(new Error('Error retrieving columns from MLS.'))
      else
        for column in $scope.columns
          $scope.formItems[schema][column].disabled = true if $scope.formItems[schema][column]?
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
      formatOnSave()
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
        $scope.schemaOptions[schema].columns = rmapsAdminConstants.defaults.schemaOptions[schema].columns
        $scope.mlsData.current[schema].table = ''
        cleanCurrentColumns(schema)


        updateFormItems({schema, state:true})
        promise = getTableOptions(schema)

      else if toStep == 2 # table option just changed, reset table and fields
        $scope.schemaOptions[schema].columns = rmapsAdminConstants.defaults.schemaOptions[schema].columns
        cleanCurrentColumns(schema)
        updateFormItems({schema, state:true, doTable:false})
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
      listingDataCols = _.keys rmapsAdminConstants.defaults.columns.listing_data
      agentDataCols = _.keys rmapsAdminConstants.defaults.columns.agent_data

      listing_data_truth = _.every ['db', 'table'].concat(listingDataCols), (k) ->
        (mlsObj.listing_data? && k of mlsObj.listing_data && mlsObj.listing_data[k] != '')
      agent_data_truth = _.every ['db', 'table'].concat(agentDataCols), (k) ->
        (mlsObj.agent_data? && k of mlsObj.agent_data && mlsObj.agent_data[k] != '')

      return listing_data_truth && agent_data_truth

    # modal for Create mlsData
    $scope.animationsEnabled = true

    $scope.openPhotoHelper = rmapsPhotoHelper($scope)

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
      $uibModal.open
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
