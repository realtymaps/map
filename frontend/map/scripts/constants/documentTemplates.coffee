app = require '../app.coffee'

# see http://webpack.github.io/docs/context.html#require-context for documentation on the API being used below

documentTemplates = {}
directoryContext = require.context("../../../../common/documentTemplates", true, /\/document\..+\.coffee$/)
for request in directoryContext.keys()
  name = /\/document\.(.+)\.coffee$/.exec(request)[1]
  documentTemplates[name] = directoryContext(request)

app.constant 'documentTemplates'.ourNs(), documentTemplates
