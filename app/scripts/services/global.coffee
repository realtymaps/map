app = require '../app.coffee'
#Global service for global variables

module.exports =
  app.factory 'Global'.ourNs(), [ =>
    @._data =
    user: window.user
    authenticated: !! window.user
    @._data
  ]
