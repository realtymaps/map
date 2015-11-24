app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsProjectsService', ($http, $log) ->

  _mockData = (project) ->
    project.notes = []
    project.notes.push
      title: 'Heads Up'
      text: 'Just a note that you should really check out this property'
    project.notes.push
      title: 'Open House'
      text: 'This property has an open house on Saturday!'
    project.notes.push
      title: 'Open House'
      text: 'This property has an open house on Saturday!'
    project.notes.push
      title: 'Open House'
      text: 'This property has an open house on Saturday!'
    project.notes.push
      title: 'Open House'
      text: 'This property has an open house on Saturday!'
    project.notes.push
      title: 'Open House'
      text: 'This property has an open house on Saturday!'

    project.neighborhoods = []
    project.neighborhoods.push
      name: 'Hill Valley'
      description: 'A friendly neighborhood for families and scientists alike'
    project.neighborhoods.push
      name: 'Park Place'
      description: 'Kinda expensive...'
    project.neighborhoods.push
      name: 'South Park'
      description: 'A great place to live if you like comedy'
    project.neighborhoods.push
      name: 'Monticello'
      description: 'Not the famous one'

    project.favorites = []
    project.favorites.push
      name: '3333 Three Ave'
      price: 1000000
      bedrooms: 3
      baths_total: 2
      finished_sqft: 2000
      year_built: 1980
      street_address_num: 1200
      street_address_name: 'Main St'
      owner_city: 'Springfield'
      owner_state: 'IL'
      owner_zip: '55555'
      status: 'pending'
    project.favorites.push
      name: '4444 Four St'
      price: 2500000
      bedrooms: 4
      baths_total: 4
      finished_sqft: 3200
      year_built: 1971
      street_address_num: 489
      street_address_name: 'Oak Ave'
      owner_city: 'Villville'
      owner_state: 'FL'
      owner_zip: '55555'
      status: 'for sale'

    _.defaults project,
      sqft: 2000
      beds: 3
      baths: 2
      minPrice: 50000
      maxPrice: 100000
      archived: false

  _update = (project) ->
    $http.put backendRoutes.projectSession.root + "/#{project.id}", project


  getProject: (id) ->
    $http.get backendRoutes.projectSession.root + "/#{id}"
    .then (response) ->
      project = response.data
      _mockData project
      project

  saveProject: (project) ->
    _update project

  createProject: (project) ->
    $http.post backendRoutes.userSession.newProject, project

  delete: (project) ->
    $http.delete backendRoutes.projectSession.root + "/#{project.id}"

  drawnShapes: (profile) ->
    rootUrl = backendRoutes.projectSession.drawnShapes.replace(":id",profile.project_id)

    _byIdUrl = (shape) ->
      backendRoutes.projectSession.drawnShapesById
      .replace(":id",profile.id)
      .replace(":drawn_shapes_id",shape.properties.id)

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
      normal.id = shape.properties.id if shape.properties?.id?
      normal.shape_extras = shape.properties.shape_extras if shape.properties?.shape_extras?
      normal

    getAll: (cache = false) ->
      $http.get rootUrl, cache: cache
      .then ({data}) ->
        data

    create: (shape) ->
      $http.post rootUrl, _normalize shape

    update: (shape) ->
      $http.put _byIdUrl(shape), _normalize shape

    delete: (shape) ->
      $http.delete _byIdUrl(shape)
