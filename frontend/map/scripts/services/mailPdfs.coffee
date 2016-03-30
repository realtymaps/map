_ = require 'lodash'
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'

app.service 'rmapsMailPdfService', ($log, $http, $sce) ->
  $log = $log.spawn 'mail:rmapsMailPdfService'
  pdfAPI = backendRoutes.pdfUpload.apiBaseMailPdf

  get: (query) ->
    $http.get pdfAPI, cache: false, params: query
    .then ({data}) ->
      data

  create: (entity) ->
    $http.post pdfAPI, entity

  remove: (aws_key) ->
    throw new Error('must have id') unless aws_key
    id = '/' + encodeURIComponent aws_key
    $http.delete(pdfAPI + id)

  update: (entity) ->
    throw new Error('entity must have id') unless entity.id
    id = '/' + entity.id
    $http.put(pdfAPI + id, entity)

  getAsCategory: () ->
    @get()
    .then (response) ->
      _.map response, (pdf) ->
        name: pdf.filename
        thumb: '/assets/base/template_pdf_img.png'
        category: 'pdf'
        type: pdf.aws_key

  getSignedUrl: (aws_key) ->
    keyEncoded = encodeURIComponent(aws_key)
    $http.get backendRoutes.pdfUpload.getSignedUrl.replace(':aws_key', keyEncoded), cache: false
    .then ({data}) ->
      data

  validatePdf: (aws_key) ->
    keyEncoded = encodeURIComponent(aws_key)
    $http.get backendRoutes.pdfUpload.validatePdf.replace(':aws_key', keyEncoded)
    .then ({data}) ->
      data
    .catch (err) ->
      # server errors will have been handled in our alert framework, so here we send appropriate invalidation msg
      {
        isValid: false
        message: err.data.alert.msg
      }
