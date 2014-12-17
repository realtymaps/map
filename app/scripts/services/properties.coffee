app = require '../app.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'


app.service 'Properties'.ourNs(), [ '$http', ($http)->
    getParcelBase: (hash, mapState) -> $http.get("#{backendRoutes.parcelBase}?bounds=#{hash}&#{mapState}")
    getFilterSummary: (hash, filters, mapState) -> $http.get("#{backendRoutes.filterSummary}?bounds=#{hash}#{filters}&#{mapState}")
]