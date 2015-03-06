app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.service 'LayerFormatters'.ourNs(), [
  'Logger'.ourNs(), 'ParcelEnums'.ourNs(), "uiGmapGmapUtil", 'GoogleService'.ourNs(), '$rootScope'
  ($log, ParcelEnums, uiGmapUtil, GoogleService, $rootScope) ->

    filterSummaryHash = {}

    renderCounters =
      fill:
        directive: 0
        control: 0

    getPixelFromLatLng = (latLng, map) ->
      point = map.getProjection().fromLatLngToPoint(latLng)
      point

    isVisible = (model, requireFilterModel=false) ->
      if !model || requireFilterModel && !filterSummaryHash[model.rm_property_id]
        return false
      # by returning savedDetails.isSaved false instead of undefined it allows us to tell the difference
      # between parcels and markers. Where parcels do not have rm_status (always).
      # depends on properties.coffee saveProperty returning savedDetails.isSave of false or true (not undefined savedDetails)
      filterModel = filterSummaryHash[model.rm_property_id] or model
      return filterModel.passedFilters || filterModel.savedDetails?.isSaved

    # TODO - Dan - this will need some more attention to make it a bit more intelligent.  This was my quick attempt for info box offests.
    getWindowOffset = (map, mls, width = 290) ->
      return if not mls or not map
      center = getPixelFromLatLng(map.getCenter(), map)
      point = getPixelFromLatLng(uiGmapUtil.getCoords(mls.geom_point_json), map)
      quadrant = ''
      quadrant += (if (point.y > center.y) then "b" else "t")
      quadrant += (if (point.x < center.x) then "l" else "r")
      if quadrant is "tr"
        offset = new google.maps.Size(-1 * width, 20)
      else if quadrant is "tl"
        offset = new google.maps.Size(30, 20)
      else if quadrant is "br"
        offset = new google.maps.Size(-1 * width, -340)
      else offset = new google.maps.Size(30, -340)  if quadrant is "bl"
      offset

    parcels = do ->
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

      # fillOpts is unique to uiGmap since we are interacting directly with the gPoly we need the real options
      gOptsFromUiGmapFill = (fillOpts) ->
        fillColor: fillOpts.color
        fillOpacity: fillOpts.opacity

      getFillColor = (parcel, logged) ->
        unless logged
          renderCounters.fill.control += 1
          $log.info "fill: from control @ count: #{renderCounters.fill.control}"
        return {} unless parcel
        parcel = GoogleService.UiMap.getCorrectModel(parcel)
        model = filterSummaryHash[parcel.rm_property_id] || parcel

        if model.savedDetails?.isSaved
          status = 'saved'
        else if model.passedFilters
          status = model.rm_status
        else
          status = 'default'

        colors = if parcel.isMousedOver then hoverColors else normalColors
        color: colors[status]
        opacity: '0.7'

      labelFromStreetNum = (parcel) ->
        return {} unless parcel
        parcel = GoogleService.UiMap.getCorrectModel(parcel)
        icon: ' '
        labelContent: "<span class='address-label'>#{String.orNA parcel.street_address_num}</span>"
        labelAnchor: "10 10"
        zIndex: 1
        markerType: "streetNum"

      _strokeColor = "#1269D8"
      _strokeWeight = 1.5

      fill: (parcel) ->
        return unless parcel?.rm_property_id?
        renderCounters.fill.directive += 1
        $log.info "fill: from directive @ count: #{renderCounters.fill.directive}, id: #{parcel.rm_property_id}"
        getFillColor(parcel, logged = true)
      labelFromStreetNum: labelFromStreetNum
      strokeColor: _strokeColor
      strokeWeight: _strokeWeight
      style:
        featureType: "administrative.land_parcel",
        elementType: "geometry.stroke",
        stylers: [
          { "color": _strokeColor },
          { "weight": _strokeWeight }
        ]

      optionsFromFill: (parcel) ->
        gOptsFromUiGmapFill getFillColor(parcel)

    mls = do ->
      markersBSLabel = {}
      markersBSLabel[ParcelEnums.status.sold] = 'sold-property'
      markersBSLabel[ParcelEnums.status.pending] = 'pending-property'
      markersBSLabel[ParcelEnums.status.forSale] = 'sale-property'
      markersBSLabel[ParcelEnums.status.notForSale] = 'notsale-property'
      markersBSLabel['saved'] = 'saved-property'

      markerOptionsFromForSale: (mls) ->
        return {} unless mls
        if not mls.price
          formattedPrice = " &nbsp; &nbsp; &nbsp;"
        else if mls.price >= 1000000
          formattedPrice = '$'+casing.upper numeral(mls.price).format('0.00a'), '.'
        else
          formattedPrice = '$'+casing.upper numeral(mls.price).format('0a'), '.'

        if mls.isMousedOver
          hovered = ' label-hovered'
          zIndex = 4
        else
          hovered = ''
          zIndex = 2

        if mls.savedDetails?.isSaved
          status = 'saved'
        else
          status = mls.rm_status

        icon: ' '
        labelContent: "<h4><span class='label label-#{markersBSLabel[status]}#{hovered}'>#{formattedPrice}</span></h4>"
        labelAnchor: "30 50"
        zIndex: zIndex
        markerType: "price"
        visible: isVisible(mls, true)

      getWindowOffset: getWindowOffset

    #public
    Parcels: parcels
    MLS: mls
    updateFilterSummaryHash: (hash) ->
      filterSummaryHash = hash
    isVisible: isVisible


]
