app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'


app.service 'Properties'.ourNs(), [ '$http', ($http)->
    getParcelBase: (hash) -> $http.get("#{backendRoutes.parcelBase}?bounds=#{hash}")
    getFilterSummary: (hash, filters) -> $http.get("#{backendRoutes.filterSummary}?bounds=#{hash}#{filters}")
]