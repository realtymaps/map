app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.service 'rmapsLobService', ($log, $http) ->
  $log = $log.spawn 'service:rmapsLobService'

  _getQuoteAndPdf = (campaignId) ->
    $http.get(backendRoutes.snail.quote.replace(':campaign_id', campaignId), alerts: false)
    .then (response) ->
      $log.debug () -> "_getQuoteAndPdf response: #{JSON.stringify(response)}"
      response.data

  getPdf: (campaignId) ->
    _getQuoteAndPdf(campaignId).then (data) ->
      data.pdf

  getQuote: (campaignId) ->
    _getQuoteAndPdf(campaignId).then (data) ->
      data.price

  send: (campaignId) ->
    url = backendRoutes.snail.send.replace(':campaign_id', campaignId)
    $http.post(url, {}, alerts: false)
    .success (data) ->
      $log.debug () -> "lob data response:\n#{JSON.stringify(data)}"
      data
