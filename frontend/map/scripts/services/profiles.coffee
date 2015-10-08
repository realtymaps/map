app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsProjectsService', ($http, rmapsprincipal) ->
  save: (projectName) ->
    $http.post backendRoutes.userSession.newProject, projectName: projectName
    .then ({data}) ->
      rmapsprincipal.setIdentity data.identity
      data

  archive: (project) ->
    project.project_archived = !project.project_archived
    $http.put backendRoutes.user_projects.root + "/#{project.project_id}",
      id: project.project_id
      name: project.project_name
      archived: project.project_archived
