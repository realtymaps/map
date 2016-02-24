app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsProjectsService', ($http, $log, $rootScope, rmapsPrincipalService, rmapsEventConstants) ->

  _mockData = (project) ->

    project.neighbourhoods = []
    project.neighbourhoods.push
      name: 'Hill Valley'
      description: 'A friendly neighbourhood for families and scientists alike'
    project.neighbourhoods.push
      name: 'Park Place'
      description: 'Kinda expensive...'
    project.neighbourhoods.push
      name: 'South Park'
      description: 'A great place to live if you like comedy'
    project.neighbourhoods.push
      name: 'Monticello'
      description: 'Not the famous one'

    _.defaults project,
      sqft: 2000
      beds: 3
      baths: 2
      minPrice: 50000
      maxPrice: 100000
      archived: false

  service =
    update: (id, project) ->
      $http.put backendRoutes.projectSession.root + "/#{id}", project

    getProjects: (cache = false) ->
      $http.get backendRoutes.projectSession.root, cache: cache
      .then (response) ->
        projects = response.data
        _.each projects, _mockData
        projects

    getProject: (id, cache = false) ->
      $http.get backendRoutes.projectSession.root + "/#{id}", cache: cache
      .then (response) ->
        project = response.data
        _mockData project
        project

    saveProject: (project) ->
      service.update (project.project_id | project.id), project

    createProject: (project) ->
      $http.post backendRoutes.userSession.newProject, project
      .then (response) ->
        rmapsPrincipalService.setIdentity response.data.identity
        $rootScope.$emit rmapsEventConstants.principal.profile.addremove, response.data.identity

    delete: (project) ->
      $http.delete backendRoutes.projectSession.root + "/#{project.id}"
      .then (response) ->
        rmapsPrincipalService.setIdentity response.data.identity
        $rootScope.$emit rmapsEventConstants.principal.profile.addremove, response.data.identity

    drawnShapes: (profile) ->
      $logDraw = $log.spawn("frontend:projects:drawnShapes")
      rootUrl = backendRoutes.projectSession.drawnShapes.replace(":id",profile.project_id)

      getList = (cache = false) ->
        $http.get rootUrl, cache: cache
        .then ({data}) ->
          data

      _byIdUrl = (shape) ->
        backendRoutes.projectSession.drawnShapesById
        .replace(":id", profile.project_id)
        .replace(":drawn_shapes_id",shape.id || shape.properties.id)

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
        normal.neighbourhood_name = shape.properties.neighbourhood_name || null
        normal.neighbourhood_details = shape.properties.neighbourhood_details || null
        normal

      getList: getList

      getListNormalized: (cache = false) ->
        getList(cache).then (geojson) ->
          return [] unless geojson
          {features} = geojson
          features

      create: (shape) ->
        $http.post rootUrl, _normalize shape
        .catch (error) ->
          $logDraw.error error

      update: (shape) ->
        $http.put _byIdUrl(shape), _normalize shape
        .catch (error) ->
          $logDraw.error error

      delete: (shape) ->
        $http.delete _byIdUrl(shape)
        .catch (error) ->
          $logDraw.error error
