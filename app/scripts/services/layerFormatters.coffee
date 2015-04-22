app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.factory 'LayerFormatters'.ourNs(), [
  'Logger'.ourNs(), 'ParcelEnums'.ourNs(), "uiGmapGmapUtil", 'GoogleService'.ourNs(), '$rootScope'
  ($log, ParcelEnums, uiGmapUtil, GoogleService, $rootScope) ->

    (mapCtrl) ->

      _filterSummary = ->
        mapCtrl.scope.map.markers.filterSummary

      renderCounters =
        fill:
          directive: 0
          control: 0

      _getPixelFromLatLng = (latLng, map) ->
        point = map.getProjection().fromLatLngToPoint(latLng)
        point

      _isVisible = (model, requireFilterModel=false) ->
        if !model || requireFilterModel && !_filterSummary()[model.rm_property_id]
          return false
        # by returning savedDetails.isSaved false instead of undefined it allows us to tell the difference
        # between parcels and markers. Where parcels do not have rm_status (always).
        # depends on properties.coffee saveProperty returning savedDetails.isSave of false or true (not undefined savedDetails)
        filterModel = _filterSummary()[model.rm_property_id] or model
        return filterModel.passedFilters || filterModel.savedDetails?.isSaved

      _parcels = do ->

        _strokeColor = "#1269D8"
        _strokeWeight = 1.5

        _parcelBaseStyle =
          weight: _strokeWeight
          opacity: 1
          color: _strokeColor
          fillColor: 'transparent'

        normalColors = {}
        normalColors[ParcelEnums.status.sold] = '#FF4A4A'
        normalColors[ParcelEnums.status.pending] = '#8C3DAA'
        normalColors[ParcelEnums.status.forSale] = '#1FDE12'
        normalColors[ParcelEnums.status.notForSale] = '#45A0D9'
        normalColors['saved'] = '#F3F315'
        normalColors['default'] = 'transparent'

        hoverColors = {}
        hoverColors[ParcelEnums.status.sold] = '#A33'
        hoverColors[ParcelEnums.status.pending] = '#537'
        hoverColors[ParcelEnums.status.forSale] = '#191'
        hoverColors[ParcelEnums.status.notForSale] = '#379'
        hoverColors['saved'] = '#AA1'
        hoverColors['default'] = 'rgba(153,153,153,.8)'


        labelFromStreetNum = (model) ->
          _.extend model,
            markerType: "streetNum"
            icon:
              type: 'div'
              iconSize: [10, 10]
              html: "<span class='address-label'>#{String.orNA model.street_address_num}</span>"
            zIndex: 1

        labelFromStreetNum: labelFromStreetNum

        style: _parcelBaseStyle


        getStyle : (feature, layerName) ->
          return {} unless feature
          if feature.savedDetails?.isSaved
            status = 'saved'
          else if feature?.rm_status?
            status = feature?.rm_status
          else
            status = 'default'

          colors = if feature?.isMousedOver then hoverColors else normalColors
          color = colors[status]

          weight: if layerName == 'parcelBase' then _parcelBaseStyle.weight else 2
          opacity: 1
          color: if layerName == 'parcelBase' then _parcelBaseStyle.color else color
          fillColor: color
          fillOpacity: .75

      _mls = do ->
        markersBSLabel = {}
        markersBSLabel[ParcelEnums.status.sold] = 'sold-property'
        markersBSLabel[ParcelEnums.status.pending] = 'pending-property'
        markersBSLabel[ParcelEnums.status.forSale] = 'sale-property'
        markersBSLabel[ParcelEnums.status.notForSale] = 'notsale-property'
        markersBSLabel['saved'] = 'saved-property'

        setMarkerPriceOptions: (model) ->
          return {} unless model
          if not model.price
            formattedPrice = " &nbsp; &nbsp; &nbsp;"
          else if model.price >= 1000000
            formattedPrice = '$'+casing.upper numeral(model.price).format('0.00a'), '.'
          else
            formattedPrice = '$'+casing.upper numeral(model.price).format('0a'), '.'

          if model.isMousedOver
            hovered = ' label-hovered'
            zIndex = 4
          else
            hovered = ''
            zIndex = 2

          if model.savedDetails?.isSaved
            status = 'saved'
          else
            status = model.rm_status

          _.extend model,
            markerType: "price"
            icon:
              type: 'div'
              iconSize: [60, 30]
              html: "<h4><span class='label label-#{markersBSLabel[status]}#{hovered}'>#{formattedPrice}</span></h4>"

        setMarkerManualClusterOptions: (model) ->
          return {} unless model
          clusterSize = 'small'
          clusterSize = 'medium' if model.count > 10
          clusterSize = 'large' if model.count > 50

          #important for the clusterer css a div must have child span
          _.extend model,
            markerType: "cluster"
            icon:
              type: 'div'
              iconSize: [60, 30]
              html: """
                <div class='leaflet-marker-icon marker-cluster marker-cluster-#{clusterSize} leaflet-zoom-animated'
                  style='margin-left: -20px; margin-top: -20px; width: 40px; height: 40px;'>
                    <div>
                      <span>#{model.count}</span>
                    </div>
                </div>"""


          visible: true

      #public
      Parcels: _parcels
      MLS: _mls
      isVisible: _isVisible
      setDataOptions: (data, optionsFormatter) ->
        _.each data, (model,k) =>
          optionsFormatter(model)
        data

]
