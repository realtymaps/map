app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

app.service 'Properties'.ourNs(), [ '$http', ($http)->
    getCounty: (hash) -> $http.get("#{backendRoutes.county.root}?bounds=#{hash}")
    getParcelsPolys: (hash) -> $http.get("#{backendRoutes.parcels.polys}?bounds=#{hash}")
]