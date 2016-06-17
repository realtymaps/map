app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.service 'rmapsMailCampaignService', (
  $log,
  $http,
  $sce,
  $rootScope,
  rmapsPrincipalService,
  rmapsProfilesService,
  rmapsEventConstants
) ->
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
        getPromise = $http.get(backendRoutes.mail.getProperties.replace(':project_id', project_id), cache: false)
        .then ({data}) ->
          _mail = data

      else
        getPromise

    getMail: (propertyId) ->
      return false unless propertyId

      _.find(_mail, 'rm_property_id', propertyId)

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

    getQuoteAndPdf: (campaignId) ->
      $http.get(backendRoutes.snail.quote.replace(':campaign_id', campaignId), alerts: false, cache: false)
      .then ({data}) ->
        $log.debug () -> "getQuoteAndPdf response: #{JSON.stringify(data)}"
        data

    create: (entity) ->
      $http.post mailAPI, entity
      .then (result) ->
        if !entity.id
          service.getProjectMail true
        result

    remove: (id) ->
      throw new Error('must have id') unless id
      id = '/' + id if id
      $http.delete(mailAPI + id)

    update: (entity) ->
      throw new Error('entity must have id') unless entity.id
      id = '/' + entity.id
      $http.put(mailAPI + id, entity)

    send: (campaignId) ->
      url = backendRoutes.snail.send.replace(':campaign_id', campaignId)
      $http.post(url, {}, alerts: false)
      .success (data) ->
        $log.debug () -> "lob data response:\n#{JSON.stringify(data)}"
        data
