app = require '../app.coffee'

app.service 'RenderPdfBlob'.ourNs(), [ '$q', 'documentTemplates'.ourNs(), ($q, documentTemplates) ->
  toBlobUrl: (templateId, data, options = {}) ->
    stream = blobStream()
    documentTemplates[templateId].render(data, stream)
    deferred = $q.defer();
    stream.on 'finish', () -> deferred.resolve(stream.toBlobURL('application/pdf'))
    stream.on 'error', (err) -> deferred.reject(err)
    deferred.promise
]
