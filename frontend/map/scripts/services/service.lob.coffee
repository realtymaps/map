app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.service 'rmapsLobService', ($log, $http) ->
  $log = $log.spawn 'service:rmapsLobService'
  quoteUrl = backendRoutes.snail.quote
  sendUrl = backendRoutes.snail.send

  handlePost = (postParams...) ->
    $http.post(postParams...).success (data) ->
      $log.debug () -> "lob data response:\n#{JSON.stringify(data)}"
      data


  getQuote: (lobData) ->
    handlePost(quoteUrl, lobData, alerts:false).then (response) ->
      $log.debug () -> "getQuote response: #{JSON.stringify(response)}"
      response.data

  submit: (lobData) ->
    url = sendUrl.replace(':campaign_id', lobData.campaign.id)
    handlePost(url, lobData, alerts:false)
