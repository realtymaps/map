app = require '../app.coffee'

module.exports = app.factory 'RedirectInterceptor'.ourNs(), [ '$location',
  ($location) ->
    'response': (response) ->
      if response.data?.redirectUrl
        $location.path(response.data?.redirectUrl)
      response
]
.config ['$httpProvider', ($httpProvider) ->
  $httpProvider.interceptors.push 'RedirectInterceptor'.ourNs()
]
