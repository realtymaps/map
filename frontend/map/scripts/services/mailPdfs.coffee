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

  remove: (id) ->
    throw new Error('must have id') unless id
    id = '/' + id if id
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
    $http.get backendRoutes.pdfUpload.getSignedUrl.replace(':id', keyEncoded)
    .then ({data}) ->
      data

  validatePdf: (aws_key) ->
    keyEncoded = encodeURIComponent(aws_key)
    $http.get backendRoutes.pdfUpload.validatePdf.replace(':id', keyEncoded)
    .then ({data}) ->
      data
