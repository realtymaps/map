###globals _,L###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.factory 'rmapsDrawnProfileFactory', (
$log,
$http,
rmapsLeafletHelpers) ->

  (profile) ->
    ###eslint-disable###
    $logDraw = $log.spawn("projects:drawnShapes")
    ###eslint-enable###
    rootUrl = backendRoutes.projectSession.drawnShapes.replace(":id",profile.project_id)
    areaUrl = backendRoutes.projectSession.areas.replace(":id",profile.project_id)

    getList = (cache = false) ->
      $http.getData rootUrl, cache: cache

    getAreas = (cache = false) ->
      $http.getData areaUrl, cache: cache

    getAreaById = (projectId, drawnShapeId, cache = false) ->
      $http.get _byIdUrl(projectId, drawnShapeId)

    _byIdUrl = (projectId, drawnShapeId) ->
      backendRoutes.projectSession.drawnShapesById
      .replace(":id", projectId)
      .replace(":drawn_shapes_id", drawnShapeId)

    _byIdUrlFromShape = (shape) ->
      _byIdUrl(profile.project_id, shape.id || shape.properties.id)

    _getGeomName = (type) ->
      switch type
        when 'Point' then 'geom_point_json'
        when 'Polygon' then 'geom_polys_json'
        when 'LineString' then 'geom_line_json'
        else
          throw new Error 'geom type not supported'


    _normalize = (shape) ->
      unless shape.geometry
        throw new Error("Shape must be GeoJSON with a geometry")
      normal = {}
      normal[_getGeomName(shape.geometry.type)] = shape.geometry
      normal.project_id = profile.project_id
      if shape.id?
        normal.id = shape.id
      if shape.shape_extras?
        normal.shape_extras = shape.shape_extras
        
      normal.area_name = if shape.area_name? then shape.area_name else null
      normal.area_details = shape.area_details || null
      normal

    _normalizedList = (geojson) ->
      return [] unless geojson
      {features} = geojson
      features

    getList: getList

    getAreas: getAreas

    getAreaById: getAreaById

    getAreasNormalized: (cache) ->
      getAreas(cache).then _normalizedList

    getAreaByIdNormalized: (id, cache = false) ->
      getAreaById(id, cache)
      .then ({data}) ->
        features = _normalizedList(data)
        return features[0]

    getListNormalized: (cache = false) ->
      getList(cache).then _normalizedList

    create: (shape) ->
      $http.post rootUrl, _normalize shape

    update: (shape) ->
      $http.put _byIdUrlFromShape(shape), _normalize shape

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
