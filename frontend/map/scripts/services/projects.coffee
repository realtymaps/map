app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsProjects', ($rootScope, $http, rmapsprincipal, rmapsevents, rmapsPromiseThrottler, $log) ->

  _mockData = (project) ->
    project.clients = []
    project.clients.push
      first_name: 'Buddy'
      last_name: 'Holly'
      email: 'buddyholly@some.domain'
      address_1: '123 Main St'
      address_2: 'New York, NY'
      zip: '55555'
      cell_phone: '1234567890'
      work_phone: '5555555555'
    project.clients.push
      first_name: 'Will'
      last_name: 'Farrell'
      email: 'willfarrell@some.domain'
      address_1: '555 Some St'
      address_2: 'Springfield, IL'
      zip: '55555'
      cell_phone: '1234567890'
      work_phone: '5555555555'

    project.notes = []
    project.notes.push
      title: 'Heads Up'
      text: 'this is a note that you should really check out this property'
    project.notes.push
      title: 'Open House'
      text: 'this property has an open house on Saturday!'

    project.neighborhoods = []
    project.neighborhoods.push
      name: 'Hill Valley'
      description: 'a friendly neighborhood for families and scientists alike'
    project.neighborhoods.push
      name: 'Park Place'
      description: 'kinda expensive...'

    project.favorites = []
    project.favorites.push
      name: '3333 Three Ave'
      price: 1000000
      bedrooms: 3
      baths_total: 2
      finished_sqft: 2000
      year_built: 1980
      street_address_num: 1200
      street_address_name: 'Main'
      owner_city: 'Springfield'
      owner_sate: 'IL'
      status: 'pending'
    project.favorites.push
      name: '4444 Four St'
      price: 2500000
      bedrooms: 4
      baths_total: 4
      finished_sqft: 3200
      year_built: 1971
      street_address_num: 489
      street_address_name: 'Oak'
      owner_city: 'Villville'
      owner_sate: 'FL'
      status: 'for sale'

    _.defaults project,
      sqft: 2000
      beds: 3
      baths: 2
      minPrice: 50000
      maxPrice: 100000
      archived: false

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

    archive: (project) ->
      project.archived = !project.archived
      $http.put backendRoutes.projectSession.root + "/#{project.id}", project
