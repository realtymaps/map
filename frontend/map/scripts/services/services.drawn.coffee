###globals _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.factory 'rmapsDrawnProfileFactory', (
$log
$http
rmapsLeafletHelpers
rmapsHttpTempCache
) ->

  (profile) ->
    ###eslint-disable###
    $logDraw = $log.spawn("projects:drawnShapes")
    ###eslint-enable###
    rootUrl = backendRoutes.projectSession.drawnShapes.replace(":id",profile.project_id)
    areaUrl = backendRoutes.projectSession.areas.replace(":id",profile.project_id)

    getList = (cache = true) ->
      rmapsHttpTempCache {
        url: rootUrl
        promise: $http.getData rootUrl, cache: cache
      }

    getAreas = (cache = true) ->
      rmapsHttpTempCache {
        url: areaUrl
        promise: $http.getData areaUrl, cache: cache
      }

    getAreaById = (projectId, drawnShapeId, cache = true) ->
      url = _byIdUrl(projectId, drawnShapeId)
      rmapsHttpTempCache {
        url
        promise: $http.get(url, cache: cache)
      }


    _byIdUrl = (projectId, drawnShapeId) ->
      backendRoutes.projectSession.drawnShapesById
      .replace(":id", projectId)
      .replace(":drawn_shapes_id", drawnShapeId)

    _byIdUrlFromShape = (shape) ->
      _byIdUrl(profile.project_id, shape.id || shape.properties.id)

    _getGeomName = (type) ->
      switch type
        when 'Point' then 'geometry_center'
        when 'Polygon' then 'geometry'
        when 'LineString' then 'geometry_line'
        else
          throw new Error 'geom type not supported'


    ###
      Public: Function is intended to normalize a shape geojson object to make it easier to save on the backend.

      NOTE: If you find your self trying to move fields that are not in properties THEN THERE is something wrong in the
      backend service.drawnShapes. Basically it is missing a toMove column.

      All fields should be in properties at all times to be valid geojson.

     - `shapeGeoJson` Geojson object to be saved {object geojson}.

      Returns the [Description] as `undefined`.
    ###
    normalize = (shapeGeoJson) ->
      unless shapeGeoJson.geometry
        throw new Error("Shape must be GeoJSON with a geometry")
      normal = {}
      normal[_getGeomName(shapeGeoJson.geometry.type)] = shapeGeoJson.geometry
      normal.project_id = profile.project_id
      if shapeGeoJson.properties.id?
        normal.id = shapeGeoJson.properties.id
      if shapeGeoJson.properties.shape_extras?
        normal.shape_extras = shapeGeoJson.properties.shape_extras

      normal.area_name = if shapeGeoJson.properties.area_name? then shapeGeoJson.properties.area_name else null
      normal.area_details = shapeGeoJson.properties.area_details || null
      normal

    normalizedList = (geojson) ->
      return [] unless geojson
      {features} = geojson
      features

    normalize: normalize

    normalizedList: normalizedList

    getList: getList

    getAreas: getAreas

    getAreaById: getAreaById

    getAreasNormalized: (cache) ->
      getAreas(cache).then normalizedList

    getAreaByIdNormalized: (id, cache = false) ->
      getAreaById(id, cache)
      .then ({data}) ->
        features = normalizedList(data)
        return features[0]

    getListNormalized: (cache = false) ->
      getList(cache).then normalizedList

    create: (shape) ->
      $http.post rootUrl, normalize shape, cache: false

    update: (shape) ->
      $http.put _byIdUrlFromShape(shape), normalize shape

    delete: (shape) ->
      $http.delete _byIdUrlFromShape(shape)

    getDrawnItems: (cache = false, mainFn = 'getList') ->
      @[mainFn](cache)
      .then (drawnShapes) ->
        rmapsLeafletHelpers.geoJsonToFeatureGroup(drawnShapes)

    getDrawnItemsAreas: (cache) ->
      @getDrawnItems(cache, 'getAreas')

app.service 'rmapsDrawnUtilsService',
($http, $log, $rootScope, rmapsPrincipalService, rmapsDrawnProfileFactory) ->
  $log = $log.spawn("map:rmapsDrawnUtilsService")

  createDrawnSvc = () ->
    if profile = rmapsPrincipalService.getCurrentProfile()
      $log.debug('profile: project_id ' + profile.project_id)
      rmapsDrawnProfileFactory(profile)

  _getShapeModel = (layer) ->
    _.merge layer.model, layer.toGeoJSON()

  eachLayerModel = (layersObj, cb) ->
    unless layersObj?
      $log.error("layersObj is undefined")
      return
    layersObj.getLayers().forEach (layer) ->
      cb(_getShapeModel(layer), layer)

  {
    createDrawnSvc
    eachLayerModel
  }
