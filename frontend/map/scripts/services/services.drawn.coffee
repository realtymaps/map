###globals L###
app = require '../app.coffee'

app.service 'rmapsDrawnService',
($http, $log, $rootScope, rmapsPrincipalService, rmapsProjectsService) ->
  $log = $log.spawn("map:rmapsDrawnService")

  getDrawnShapesSvc = () ->
    drawnShapesFact = rmapsProjectsService.drawnShapes
    drawnShapesSvc = null
    if profile = rmapsPrincipalService.getCurrentProfile()
      $log.debug('profile: project_id' + profile.project_id)
      drawnShapesSvc = drawnShapesFact(profile) unless drawnShapesSvc

    drawnShapesSvc

  getDrawnItems = (mainFn = 'getList') ->
    drawnItems = new L.FeatureGroup()
    getDrawnShapesSvc()?[mainFn]()
    .then (drawnShapes) ->
      # TODO: drawn shapes will get its own tables for GIS queries
      $log.debug 'fetched shapes'
      L.geoJson drawnShapes,
        onEachFeature: (feature, layer) ->
          $log.debug feature
          if feature.properties?.shape_extras?.type = 'Circle'
            layer = L.Circle.createFromFeature feature
          layer.model = feature
          drawnItems.addLayer layer
      drawnItems

  getDrawnItemsNeighborhoods = () ->
    getDrawnItems('getNeighborhoods')

  _getShapeModel = (layer) ->
    _.merge layer.model, layer.toGeoJSON()

  eachLayerModel = (layersObj, cb) ->
    unless layersObj?
      $log.error("layersObj is undefined")
      return
    layersObj.getLayers().forEach (layer) ->
      cb(_getShapeModel(layer), layer)

  {
    getDrawnShapesSvc
    getDrawnItems
    getDrawnItemsNeighborhoods
    eachLayerModel
  }
