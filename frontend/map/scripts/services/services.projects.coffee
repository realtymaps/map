_ = require 'lodash'
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsProjectsService', (
$http
$log
$rootScope
rmapsPrincipalService
rmapsProfilesService
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
      .then ({data}) ->
        rmapsProfilesService.addProfile(data.identity.profiles[data.identity.currentProfileId])
        return data.identity.profiles[data.identity.currentProfileId]

    deleteProject: (project_id) ->
      $http.delete backendRoutes.projectSession.root + "/#{project_id}"
      .then ({data}) ->
        profile = _.find data.identity.profiles, 'project_id', project_id
        if profile # sandbox reset
          rmapsProfilesService.addProfile(profile)
        else
          profile = _.find $rootScope.identity.profiles, 'project_id', project_id
          rmapsProfilesService.removeProfile(id: profile.id)
        return data.identity.profiles[data.identity.currentProfileId]
