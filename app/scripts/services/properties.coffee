app = require '../app.coffee'
routes = require '../../../common/config/routes.coffee'

app.service 'Properties'.ourNs(), [ '$http', ($http)->
    getCounty: (hash) -> $http.get("#{routes.county.root}?bounds=#{hash}")
    getParcelsPolys: (hash) -> $http.get("#{routes.parcels.polys}?bounds=#{hash}")
]