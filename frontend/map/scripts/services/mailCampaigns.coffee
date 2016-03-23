app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.service 'rmapsMailCampaignService', ($log, $http, $sce, $rootScope, rmapsPrincipalService, rmapsProfilesService, rmapsEventConstants) ->
  $log = $log.spawn 'mail:mailCampaignService'
  mailAPI = backendRoutes.mail.apiBaseMailCampaigns

  getPromise = null
  _mail = []

  $rootScope.$onRootScope rmapsEventConstants.principal.profile.updated, (event, profile) ->
    $log.debug 'Mail Service profile updated event'
    service.getProjectMail true

  $rootScope.$onRootScope rmapsEventConstants.principal.logout.success, (event, profile) ->
    $log.debug 'Mail Service user logout event'
    service.clear()

  service =

    ###
    # Project-centric methods used by map, property buttons
    ###

    getProjectMail: (force = false) ->
      if !getPromise || force
        project_id = rmapsProfilesService.currentProfile?.project_id
        getPromise = $http.get("/mailProperties/#{project_id}", cache: false)
        .then ({data}) ->
          _mail = data
      else
        getPromise

    getMail: (propertyId) ->
      return false unless propertyId

      _.find _mail, (mail) ->
        mail.rm_property_id == propertyId

    clear: () ->
      getPromise = null
      _mail = []

    ###
    # Generic methods -- used by mail pages
    ###

    get: (query) ->
      $http.get mailAPI, cache: false, params: query
      .then ({data}) ->
        data

    getReviewDetails: (id) ->
      throw new Error('entity must have id') unless id
      url = backendRoutes.mail.getReviewDetails.replace ':id', id
      $http.get url, cache: false
      .then ({data}) ->
        $log.debug -> "getReviewDetails data:\n#{JSON.stringify(data)}"
        data

    create: (entity) ->
      $http.post mailAPI, entity
      .then (result) ->
        service.getProjectMail true
        result

    remove: (id) ->
      throw new Error('must have id') unless id
      id = '/' + id if id
      $http.delete(mailAPI + id)
      .then (result) ->
        service.getProjectMail true
        result

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(mailAPI + id, entity)
      .then (result) ->
        service.getProjectMail true
        result
