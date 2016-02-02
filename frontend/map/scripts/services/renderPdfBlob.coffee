app = require '../app.coffee'

blobStream = require 'blob-stream'

app.service 'rmapsRenderPdfBlobService', ($q, rmapsDocumentTemplateConstants) ->
  toBlobUrl: (templateId, data, options = {}) ->
    stream = blobStream()
    rmapsDocumentTemplateConstants[templateId].render(data, stream)
    deferred = $q.defer()
    stream.on 'finish', () ->
      deferred.resolve(stream.toBlobURL('application/pdf'))
    stream.on 'error', (err) ->
      deferred.reject(err)
    deferred.promise
