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

  service =
    getProjects: () ->
      $http.get backendRoutes.projectSession.root
      .then (response) ->
        projects = response.data
        _.each projects, _mockData
        projects

    getProject: (id) ->
      $http.get backendRoutes.projectSession.root + "/#{id}"
      .then (response) ->
        project = response.data?[0]
        _mockData project
        project

    saveProject: (project) ->
      _update project

    createProject: (project) ->
      $http.post backendRoutes.userSession.newProject, project

    archive: (project) ->
      project.archived = !project.archived
      _update project
