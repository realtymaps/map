app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'


app.service 'Properties'.ourNs(), [ '$http', '$rootScope', ($http, $rootScope)->
    getCounty: (hash, filters) -> $http.get("#{backendRoutes.county.root}?bounds=#{hash}#{filters}")
    getParcelsPolys: (hash, filters) -> $http.get("#{backendRoutes.parcels.polys}?bounds=#{hash}#{filters}")
]