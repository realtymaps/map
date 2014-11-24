app = require '../app.coffee'

# logs when we change routes -- this is just for debugging / troubleshooting purposes,
# so we could remove this when we go live, or leave it there, either way
app.run ["$rootScope", ($rootScope) ->
  $rootScope.$on "$routeChangeStart", (event, nextRoute) ->
    console.log("$routeChangeStart: #{nextRoute?.$$route?.originalPath}")
]
