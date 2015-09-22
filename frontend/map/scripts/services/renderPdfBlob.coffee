app = require '../app.coffee'

blobStream = require 'blob-stream'

app.service 'rmapsRenderPdfBlob', ($q, rmapsdocumentTemplates) ->
  toBlobUrl: (templateId, data, options = {}) ->
    stream = blobStream()
    rmapsdocumentTemplates[templateId].render(data, stream)
    deferred = $q.defer()
    stream.on 'finish', () ->
      deferred.resolve(stream.toBlobURL('application/pdf'))
    stream.on 'error', (err) ->
      deferred.reject(err)
    deferred.promise
