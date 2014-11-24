# see http://webpack.github.io/docs/context.html#require-context for documentation on the API being used below

# require() all modules in the config directory
directoryContext = require.context("../config", true, /^\.\/.*\.coffee$/)
for request in directoryContext.keys()
  directoryContext(request)

# require() all modules in the runners directory
directoryContext = require.context("../runners", true, /^\.\/.*\.coffee$/)
for request in directoryContext.keys()
  directoryContext(request)


app = require '../app.coffee'
module.exports = app.controller 'MainCtrl'.ourNs(), ->
