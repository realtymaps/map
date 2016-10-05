###globals _###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsProjectsService', (
$http
$log
$rootScope
rmapsPrincipalService
rmapsEventConstants
rmapsHttpTempCache
) ->

  _mockData = (project) ->

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

    archive: (project) ->
      @update project.id, archived: !project.archived
      .then () ->
        project.archived = !project.archived

    getProjects: (cache = false) ->
      $http.get backendRoutes.projectSession.root, cache: cache
      .then (response) ->
        projects = response.data
        _.each projects, _mockData
        projects

    getProject: (id, cache = true) ->
      url = backendRoutes.projectSession.root + "/#{id}"

      rmapsHttpTempCache {
        url
        promise: $http.get url, cache: cache
        .then (response) ->
          project = response.data
          _mockData project
          project
      }

    saveProject: (project) ->
      service.update (project.project_id | project.id), project

    createProject: (project) ->
      $http.post backendRoutes.userSession.newProject, project
      .then (response) ->
        rmapsPrincipalService.setIdentity response.data.identity
        $rootScope.$emit rmapsEventConstants.principal.profile.addremove, response.data.identity

        return response.data.identity

    delete: (project) ->
      $http.delete backendRoutes.projectSession.root + "/#{project.id}"
      .then (response) ->
        rmapsPrincipalService.setIdentity response.data.identity
        $rootScope.$emit rmapsEventConstants.principal.profile.addremove, response.data.identity

        return response.data.identity
