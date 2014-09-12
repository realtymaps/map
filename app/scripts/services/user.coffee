###
User service to get current and fetch additional about the user
###
app = require '../app.coffee'

module.exports =
  app.factory 'User'.ourNs(), [ '$http', ($http) =>
    # map option from the user info via cookie or service ?
    mapOptions:
        center:
          latitude: 45
          longitude: -73
        markers: marks
        zoom: 3
  ]
