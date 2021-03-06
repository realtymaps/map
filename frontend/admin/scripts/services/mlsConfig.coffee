app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'
qs = require 'qs'


app.service 'rmapsMlsService', ['Restangular', '$http', 'rmapsEventConstants', '$rootScope', '$log',
(Restangular, $http, rmapsEventConstants, $rootScope, $log) ->

  mlsAPI = backendRoutes.mls.apiBaseMls
  mlsConfigAPI = backendRoutes.mls_config.apiBase

  getConfigs = (params = {}) ->
    Restangular.all(mlsConfigAPI).getList(params)

  postConfig = (configObj, collection) ->
    newMls = Restangular.one(mlsConfigAPI)
    _.merge newMls, configObj
    newMls.save().then (res) ->
      # add to our collection (by reference, for adding to existing dropdowns, etc)
      if collection
        collection.push(newMls)
      # for some reason even though we used save(), each subsequent .save() will keep trying posts, which inserts.
      # this hack flags it to start using 'put' when saving from now on.
      newMls.fromServer = true
      newMls

  update = (configId, mlsConfig) ->
    Restangular.all(mlsConfigAPI).one(configId).customPUT(mlsConfig)

  postMainPropertyData = (configId, mainPropertyData) ->
    Restangular.all(mlsConfigAPI).one(configId).all('propertyData').customPUT(mainPropertyData)

  postServerData = (configId, serverData) ->
    Restangular.all(mlsConfigAPI).one(configId).all('serverInfo').customPUT(serverData)

  postServerPassword = (configId, password) ->
    Restangular.all(mlsConfigAPI).one(configId).all('serverInfo').customPUT(password)

  getDatabaseList = (configId) ->
    Restangular.all(mlsAPI).one(configId).all('databases').getList()

  getObjectList = (configId) ->
    Restangular.all(mlsAPI).one(configId).all('objects').getList()

  getTableList = (configId, databaseId) ->
    Restangular.all(mlsAPI).one(configId).all('databases').one(databaseId).all('tables').getList()

  getColumnList = (configId, databaseId, tableId) ->
    Restangular.all(mlsAPI).one(configId).all('databases').one(databaseId).all('tables').one(tableId).all('columns').getList()

  getLookupTypes = (configId, databaseId, lookupId) ->
    Restangular.all(mlsAPI).one(configId).all('databases').one(databaseId).all('lookups').one(lookupId).all('types').getList()

  getDataDumpUrl = (configId, dataType, limit) ->
    # bypass XHR / $http file-dl drama, and Restangular req/res complication.
    backendRoutes.mls.getDataDump.replace(':mlsId', configId).replace(':dataType', dataType) + "?limit=#{limit}"

  getPhotoIds = ({mlsId, uuidField, photoIdField, lastModTimeField, limit}) ->
    $http.getData(backendRoutes.mls.getPhotoIds.replace(':mlsId', mlsId), {
        params: {uuidField, photoIdField, lastModTimeField, limit}
        cache: true
    })

  buildPhotoUrl = ({mlsId, database, photoId, imageId, photoType, objectsOpts}) ->
    database ?= 'Property'
    mainUrl = '//' + location.host + backendRoutes.mls.getPhotos.replace(':mlsId', mlsId).replace(':databaseId', database) + "?"
    params = {
      ids:
        "#{photoId}": imageId
      photoType
    }

    if objectsOpts?
      params.objectsOpts = objectsOpts

    # mainUrl += qs.stringify(params)
    mainUrl += 'ids=' + JSON.stringify(params.ids)
    mainUrl += '&' + qs.stringify({photoType: params.photoType})
    if objectsOpts?
      mainUrl += '&objectsOpts=' + JSON.stringify(params.objectsOpts)
    # when transform: validators.object(json:true) || validators.object() are either ok
    # then we can just use  # mainUrl += qs.stringify(params)
    $log.debug -> "buildPhotoUrl: #{mainUrl}"
    mainUrl

  testOverlapSettings = (configId) ->
    $http.getData(backendRoutes.mls.testOverlapSettings.replace(':mlsId', configId))
    .then (data) ->
      if !data || data.error
        $rootScope.$emit rmapsEventConstants.alert.spawn,
          type: 'rm-danger'
          id: "overlap-test-#{configId}"
          msg: "Bad test results: #{data.error}"
        return
      verify = if data.inOrder then 'checked' else 'unchecked'
      force = if data.actual <= 2 then 'checked' else 'unchecked'
      $rootScope.$emit rmapsEventConstants.alert.spawn,
        type: 'rm-info'
        id: "overlap-test-#{configId}"
        msg: [
          "Test results:"
          " * Expected overlap: #{data.expected}"
          " * Actual overlap: #{data.actual}"
          " * In order: #{data.inOrder}"
          ""
          "Suggestions:"
          "<b> * Verify Data Overlap</b>: <i>#{verify}</i>"
          "<b> * Force Overlap Ordering</b>: <i>#{force}</i>"
        ].join('<br/>')

  {
    getConfigs
    postConfig
    update
    postMainPropertyData
    postServerData
    postServerPassword
    getDatabaseList
    getTableList
    getColumnList
    getLookupTypes
    getDataDumpUrl
    getObjectList
    getPhotoIds
    buildPhotoUrl
    testOverlapSettings
  }

]
