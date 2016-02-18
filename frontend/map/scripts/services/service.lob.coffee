app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
_ = require 'lodash'

app.service 'rmapsLobService', ($log, $http) ->
  $log = $log.spawn 'service:rmapsLobService'
  quoteUrl = backendRoutes.snail.quote
  sendUrl = backendRoutes.snail.send

  _handlePost = (postParams...) ->
    $http.post(postParams...).success (data) ->
      $log.debug () -> "lob data response:\n#{JSON.stringify(data)}"
      data

  _getQuoteAndPdf = (lobData) ->
    _handlePost(quoteUrl, lobData, alerts:false).then (response) ->
      $log.debug () -> "getQuote response: #{JSON.stringify(response)}"
      response.data

  getPdf: (lobData) ->
    _getQuoteAndPdf(lobData).then (data)->
      data.pdf

  getQuote: (lobData) ->
    _getQuoteAndPdf(lobData).then (data)->
      data.price

  submit: (lobData) ->
    url = sendUrl.replace(':campaign_id', lobData.campaign.id)
    _handlePost(url, lobData, alerts:false)
