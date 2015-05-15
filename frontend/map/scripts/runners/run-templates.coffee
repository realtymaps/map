app = require '../app.coffee'

# see http://webpack.github.io/docs/context.html#require-context for documentation on the API being used below

#load all templates via webpack
#then load them into the angular $templateCache
app.run ($templateCache) ->
  directoryContext = require.context("../../html/views/templates", true, /\/.*\.tpl\.jade$/)
  for request in directoryContext.keys()
    name = /\/(.*)\.jade$/.exec(request)[1] + '.html'
    $templateCache.put name, directoryContext(request)
