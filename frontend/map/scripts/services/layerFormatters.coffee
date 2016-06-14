###globals _###
app = require '../app.coffee'
numeral = require 'numeral'
casing = require 'case'
pieUtil = require '../utils/util.piechart.coffee'
priceMarkerTemplate = require '../../html/includes/map/_priceMarker.jade'

app.service 'rmapsLayerFormattersService', ($log, rmapsParcelEnums, $rootScope, rmapsStylusConstants) ->

  $log = $log.spawn('map:layerFormatter')

  _isVisible = (scope, model, requireFilterModel=false) ->
    filterSummary = scope.map.markers.filterSummary
    if !model || requireFilterModel && !filterSummary[model.rm_property_id]
      return false
    # by returning savedDetails.isPinned false instead of undefined it allows us to tell the difference
    # between parcels and markers. Where parcels do not have rm_status (always).
    # depends on rmapsProperties.coffee saveProperty returning savedDetails.isSave of false or true (not undefined savedDetails)
    filterModel = filterSummary[model.rm_property_id] or model
    nonBool = filterModel.passedFilters || filterModel?.savedDetails?.isPinned
    nonBool == true

  _parcels = do ->

    _strokeColor = '#1269D8'
    _strokeWeight = 1.5

    _parcelBaseStyle =
      weight: _strokeWeight
      opacity: 1
      color: _strokeColor
      fillColor: 'transparent'

    normalColors = {}
    normalColors[rmapsParcelEnums.status.sold] = rmapsStylusConstants.$rm_sold
    normalColors[rmapsParcelEnums.status.pending] = rmapsStylusConstants.$rm_pending
    normalColors[rmapsParcelEnums.status.forSale] = rmapsStylusConstants.$rm_forsale
    normalColors[rmapsParcelEnums.status.notForSale] = rmapsStylusConstants.$rm_sold
    normalColors['saved'] = rmapsStylusConstants['$rm_saved']
    normalColors['default'] = 'transparent'

    hoverColors = {}
    hoverColors[rmapsParcelEnums.status.sold] = rmapsStylusConstants.$rm_sold_hover
    hoverColors[rmapsParcelEnums.status.pending] = rmapsStylusConstants.$rm_pending_hover
    hoverColors[rmapsParcelEnums.status.forSale] = rmapsStylusConstants.$rm_forsale_hover
    hoverColors[rmapsParcelEnums.status.notForSale] = rmapsStylusConstants.$rm_sold_hover
    hoverColors['saved'] = rmapsStylusConstants['$rm_saved_hover']
    hoverColors['default'] = 'rgba(153,153,153,.8)'


    labelFromStreetNum = (model) ->
      _.extend model,
        markerType: 'streetNum'
        icon:
          type: 'div'
          iconSize: [10, 10]
          html: "<span class='address-label'>#{String.orNA model.street_address_num}</span>"
        zIndex: 1

    labelFromStreetNum: labelFromStreetNum

    style: _parcelBaseStyle


    getStyle : (feature, layerName) ->
      return {} unless feature

      if feature?.savedDetails?.isPinned
        savedStatus = 'saved'

      if feature?.rm_status?
        status = feature?.rm_status
      else
        status = 'default'

      colors = if feature?.isMousedOver then hoverColors else normalColors

      color = colors[status] || colors['default']
      fillColor = colors[savedStatus || status] || colors['default']

      weight: if layerName == '_parcelBase' then _parcelBaseStyle.weight else 4
      opacity: 1
      color: if layerName == '_parcelBase' then _parcelBaseStyle.color else color
      fillColor: fillColor
      colorOpacity: 1
      fillOpacity: .75

  _mls = do ->
    markersBSLabel = {}
    markersBSLabel[rmapsParcelEnums.status.sold] = 'sold-property'
    markersBSLabel[rmapsParcelEnums.status.pending] = 'pending-property'
    markersBSLabel[rmapsParcelEnums.status.forSale] = 'sale-property'
    markersBSLabel[rmapsParcelEnums.status.notForSale] = 'sold-property'
    markersBSLabel['saved'] = 'saved-property'

    setMarkerPriceOptions: (model) ->
      return {} unless model
      if !model.price
        formattedPrice = '-'
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

      if model.savedDetails?.isPinned
        status = 'saved'
      else
        status = model.rm_status || model.status

      _.extend model,
        markerType: 'price'
        riseOnHover: true
        icon:
          type: 'div'
          iconSize: [60, 30]
          html: priceMarkerTemplate(price:formattedPrice, priceClasses: "label-#{markersBSLabel[status]}#{hovered}")

    setMarkerNotesOptions: (model, number) ->
      _.extend model,
        $index: number
        markerType: 'note'
        icon:
          type: 'div'
          iconSize: [30, 30]
          html: require('../../html/includes/_circleNr.jade')(number+1)

    setMarkerMailOptions: (model, number) ->
      _.extend model,
        $index: number
        markerType: 'mail'
        icon:
          type: 'div'
          iconSize: [12, 12]
          html: "<i class=\"mail-marker icon fa fa-envelope\"></i>"

    setMarkerManualClusterOptions: (model) ->
      return {} unless model
      #important for the clusterer css a div must have child span
      _.extend model,
        markerType: 'cluster'
        icon:
          type: 'div'
          html: pieUtil.pieCreateFunctionBackend(model)

  #public
  Parcels: _parcels
  MLS: _mls
  isVisible: _isVisible
  setDataOptions: (data, optionsFormatter) ->
    _.each data, (model,k) ->
      optionsFormatter(model, k)
    data
