# see http://webpack.github.io/docs/context.html#require-context for documentation on the API being used below
# JWI: I tried to make a util requireDirectory() function to handle things like this, but it failed because of how the
#      webpack parser works.  So, for now it will have to remain this small bit of copy-pasta.

# require() all modules in the config directory
directoryContext = require.context("../config", true, /^\.\/.*\.coffee$/)
for request in directoryContext.keys()
  directoryContext(request)

# require() all modules in the runners directory
directoryContext = require.context("../runners", true, /^\.\/.*\.coffee$/)
for request in directoryContext.keys()
  directoryContext(request)


# main app controller
app = require '../app.coffee'
module.exports = app.controller 'MainCtrl'.ourNs(), [ () ->
]
