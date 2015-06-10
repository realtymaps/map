###
Object list of the defined routes. It's purpose is to keep the
frontend and backend in sync
###

apiBase = '/api'


module.exports =
    wildcard:
        admin:           "/admin/*"
        frontend:        "/*"
        backend:         "#{apiBase}/*"
    user:
        identity:        "#{apiBase}/identity"
        updateState:     "#{apiBase}/identity/state"
        login:           "#{apiBase}/login"
        logout:          "#{apiBase}/logout"
    version:
        version:         "#{apiBase}/version"
    config:
        mapboxKey:         "#{apiBase}/mapbox_key"
        cartodb:           "#{apiBase}/cartodb"
    properties:
        filterSummary:   "#{apiBase}/properties/filter_summary/"
        parcelBase:      "#{apiBase}/properties/parcel_base/"
        addresses:       "#{apiBase}/properties/addresses/"
        detail:          "#{apiBase}/properties/detail/"
    snail:
        quote:            "#{apiBase}/snail/quote"
        send:             "#{apiBase}/snail/send"
    mapbox:
        upload:            "#{apiBase}/mapbox/upload"
    cartodb:
        getByFipsCodeAsFile:      "#{apiBase}/cartodb/fipscodeFile/:fipscode"
        getByFipsCodeAsStream:    "#{apiBase}/cartodb/fipscodeStream/:fipscode"
    parcel:
        getByFipsCode:            "#{apiBase}/parcel"
        getByFipsCodeFormatted:   "#{apiBase}/parcel/formatted"
        uploadToParcelsDb:        "#{apiBase}/parcel/upload"
        defineImports:            "#{apiBase}/parcel/defineimports"
    mls_config:
        getAll:                 "#{apiBase}/mls_config"
        getById:                "#{apiBase}/mls_config/:id"
        update:                 "#{apiBase}/mls_config/:id"
        updatePropertyData:     "#{apiBase}/mls_config/:id/propertyData"
        updateServerInfo:       "#{apiBase}/mls_config/:id/serverInfo"
        create:                 "#{apiBase}/mls_config/"
        createById:             "#{apiBase}/mls_config/:id"
        delete:                 "#{apiBase}/mls_config/:id"
    mls_normalization:
        getMlsRules:        "#{apiBase}/mls_config/:mlsId/rules"
        createMlsRules:     "#{apiBase}/mls_config/:mlsId/rules"
        putMlsRules:     "#{apiBase}/mls_config/:mlsId/rules"
        deleteMlsRules:     "#{apiBase}/mls_config/:mlsId/rules"
        getListRules:       "#{apiBase}/mls_config/:mlsId/rules/:list"
        createListRules:    "#{apiBase}/mls_config/:mlsId/rules/:list"
        putListRules:    "#{apiBase}/mls_config/:mlsId/rules/:list"
        deleteListRules:    "#{apiBase}/mls_config/:mlsId/rules/:list"
        getRule:            "#{apiBase}/mls_config/:mlsId/rules/:list/:ordering"
        updateRule:         "#{apiBase}/mls_config/:mlsId/rules/:list/:ordering"
        deleteRule:         "#{apiBase}/mls_config/:mlsId/rules/:list/:ordering"
    mls:
        getDatabaseList:  "#{apiBase}/mls/:mlsId/databases"
        getTableList:     "#{apiBase}/mls/:mlsId/databases/:databaseId/tables"
        getColumnList:    "#{apiBase}/mls/:mlsId/databases/:databaseId/tables/:tableId/columns"
    # hirefire secret value set from within backend/config/config.coffee
