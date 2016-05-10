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
    neighborhoodUrl = backendRoutes.projectSession.neighborhoods.replace(":id",profile.project_id)

    getList = (cache = false) ->
      $http.getData rootUrl, cache: cache

    getNeighborhoods = (cache = false) ->
      $http.getData neighborhoodUrl, cache: cache

    _byIdUrl = (shape) ->
      backendRoutes.projectSession.drawnShapesById
      .replace(":id", profile.project_id)
      .replace(":drawn_shapes_id", shape.id || shape.properties.id)

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
      if shape.properties?.id?
        normal.id = shape.properties.id
      if shape.properties?.shape_extras?
        normal.shape_extras = shape.properties.shape_extras
      normal.neighbourhood_name = if shape.properties.neighbourhood_name? then shape.properties.neighbourhood_name else null
      normal.neighbourhood_details = shape.properties.neighbourhood_details || null
      normal

    _normalizedList = (geojson) ->
      return [] unless geojson
      {features} = geojson
      features

    getList: getList

    getNeighborhoods: getNeighborhoods

    getNeighborhoodsNormalized: (cache) ->
      getNeighborhoods(cache).then _normalizedList

    getListNormalized: (cache = false) ->
      getList(cache).then _normalizedList

    create: (shape) ->
      $http.post rootUrl, _normalize shape

    update: (shape) ->
      $http.put _byIdUrl(shape), _normalize shape

    delete: (shape) ->
      $http.delete _byIdUrl(shape)

    getDrawnItems: (cache = false, mainFn = 'getList') ->
      @[mainFn](cache)
      .then (drawnShapes) ->
        rmapsLeafletHelpers.geoJsonToFeatureGroup(drawnShapes)

    getDrawnItemsNeighborhoods: (cache) ->
      @getDrawnItems(cache, 'getNeighborhoods')

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
