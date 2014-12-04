app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'

app.service 'Properties'.ourNs(), [ '$http', ($http)->
    getCounty: (hash) -> $http.get("#{backendRoutes.county.root}?bounds=#{hash}")
    getParcelsPolys: (hash) -> $http.get("#{backendRoutes.parcels.polys}?bounds=#{hash}")
    #FUlly intended to be replaced by Joe's updates
    getMLS: (hash) -> $http.get("#{backendRoutes.mls.root}?bounds=#{hash}")
]