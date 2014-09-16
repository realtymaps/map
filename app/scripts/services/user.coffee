###
User service to get current and fetch additional about the user
###
app = require '../app.coffee'

module.exports =
  app.factory 'User'.ourNs(), [ '$http', ($http) =>
    # map option from the user info via cookie or service ?
    map:
      options:{}
  ]
