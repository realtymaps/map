_ = require 'lodash'
app = require '../app.coffee'
numeral = require 'numeral'
casing = require 'case'
pieMarkerFactory = require '../utils/util.piechart.marker.coffee'
priceMarkerTemplate = require '../../html/includes/map/markers/_priceMarker.jade'
noteMarkerTemplate  = require '../../html/includes/map/markers/_noteMarker.jade'
currentLocationMarkerTemplate = require '../../html/includes/map/markers/_currentLocationMarker.jade'

app.service 'rmapsLayerFormattersService', (
  $log,
  rmapsParcelEnums,
  $rootScope,
  rmapsStylusConstants,
  rmapsMailCampaignService
) ->

  $log = $log.spawn('map:layerFormatter')

  isVisible = (scope, model, requireFilterModel=false) ->
    filterSummary = scope.map.markers.filterSummary
    if !model || requireFilterModel && !filterSummary[model.rm_property_id]
      return false
    # by returning savedDetails.isPinned false instead of undefined it allows us to tell the difference
    # between parcels and markers. Where parcels do not have status (always).
    # depends on rmapsProperties.coffee saveProperty returning savedDetails.isSave of false or true (not undefined savedDetails)
    filterModel = filterSummary[model.rm_property_id] or model
    nonBool = filterModel.passedFilters || filterModel?.savedDetails?.isPinned || filterModel?.savedDetails?.isFavorite
    nonBool == true

  Parcels = do ->

    _defaultClassName = 'rmaps-parcel'

    _strokeColor = '#1269D8'
    _strokeWeight = 1.5

    _parcelBaseStyle =
      weight: _strokeWeight
      opacity: 1
      color: _strokeColor
      fillColor: 'transparent'
      className: _defaultClassName

    normalColors = {}
    normalColors[rmapsParcelEnums.status.sold] = rmapsStylusConstants.$rm_sold
    normalColors[rmapsParcelEnums.status.pending] = rmapsStylusConstants.$rm_pending
    normalColors[rmapsParcelEnums.status.forSale] = rmapsStylusConstants.$rm_forsale
    normalColors[rmapsParcelEnums.status.discontinued] = rmapsStylusConstants.$rm_notforsale
    normalColors['saved'] = rmapsStylusConstants['$rm_saved']
    normalColors['default'] = 'transparent'

    hoverColors = {}
    hoverColors[rmapsParcelEnums.status.sold] = rmapsStylusConstants.$rm_sold_hover
    hoverColors[rmapsParcelEnums.status.pending] = rmapsStylusConstants.$rm_pending_hover
    hoverColors[rmapsParcelEnums.status.forSale] = rmapsStylusConstants.$rm_forsale_hover
    hoverColors[rmapsParcelEnums.status.discontinued] = rmapsStylusConstants.$rm_notforsale_hover
    hoverColors['saved'] = rmapsStylusConstants['$rm_saved_hover']
    hoverColors['default'] = 'rgba(153,153,153,.8)'

    style: _parcelBaseStyle

    getStyle : (feature, layerName) ->
      return {} unless feature

      className = _defaultClassName

      if feature?.savedDetails?.isPinned || feature?.savedDetails?.isFavorite
        savedStatus = 'saved'

      if feature?.status?
        status = feature?.status
      else
        status = 'default'

      colors = if feature?.isMousedOver then hoverColors else normalColors

      if feature.isHighlighted
        $log.debug 'center!!!', feature.rm_property_id
        color = 'orange'
        fillColor = 'orange'
        className = "rmaps-property-layer #{status} highlighted"
      else
        if layerName == '_parcelBase'
          color = _parcelBaseStyle.color
        else
          className = "rmaps-property-layer #{status}"
          color = colors[status] || colors['default']

        fillColor ?= colors[savedStatus || status] || colors['default']

      return {
        weight: if layerName == '_parcelBase' then _parcelBaseStyle.weight else 4
        opacity: 1
        color: color
        fillColor: fillColor
        colorOpacity: 1
        fillOpacity: .75
        className
      }

  MLS = do ->
    markersBSLabel = {}
    markersBSLabel[rmapsParcelEnums.status.sold] = 'sold-property'
    markersBSLabel[rmapsParcelEnums.status.pending] = 'pending-property'
    markersBSLabel[rmapsParcelEnums.status.forSale] = 'sale-property'
    markersBSLabel['saved'] = 'saved-property'

    setMarkerOptions: (marker) ->
      switch marker.markerType
        when 'price' then @setMarkerPriceOptions(marker)
        when 'price-group' then @setMarkerPriceGroupOptions(marker)
        when 'note' then @setMarkerNotesOptions(marker)

    setMarkerPriceOptions: (model) ->
      return {} unless model
      if !model.price
        formattedPrice = '-'
      else if model.price >= 1000000
        formattedPrice = '$'+casing.upper numeral(model.price).format('0.00a'), '.'
      else
        formattedPrice = '$'+casing.upper numeral(model.price).format('0a'), '.'

      if model.savedDetails?.isPinned || model.savedDetails?.isFavorite
        status = 'saved'
      else
        status = model.status

      _.extend model,
        markerType: 'price'
        riseOnHover: true
        icon:
          type: 'div'
          iconSize: [1, 1]
          html: priceMarkerTemplate(
            price:formattedPrice,
            priceClasses: "label-#{markersBSLabel[status]}",
            hasMail: !!rmapsMailCampaignService.getMail(model.rm_property_id)
            rm_property_id: model.rm_property_id
            isPinned: model.savedDetails?.isPinned
            isFavorited: model.savedDetails?.isFavorite
          )

    setMarkerPriceGroupOptions: (models) ->
      return {} unless models

      _.extend models,
        markerType: 'price-group'
        riseOnHover: true
        icon:
          type: 'div'
          iconSize: [1, 1]
          # html: priceMarkerTemplate(price: "#{models.grouped.properties.length} Units (#{models.grouped.name}", priceClasses: "label-saved-property")
          html: pieMarkerFactory.createBackend(models.grouped, 'pieClassGrouped')

    setMarkerNotesOptions: (model) ->
      _.extend model,
        markerType: 'note'
        icon:
          type: 'div'
          iconSize: [30, 30]
          html: noteMarkerTemplate(model)

    setMarkerMailOptions: (model, number) ->
      _.extend model,
        $index: number
        markerType: 'mail'
        icon:
          type: 'div'
          iconSize: [12, 12]
          html: '<i class="rmaps-property-layer mail-marker icon fa fa-envelope"></i>'
        zIndexOffset: 1000

    setMarkerManualClusterOptions: (model) ->
      return {} unless model
      #important for the clusterer css a div must have child span
      _.extend model,
        markerType: 'cluster'
        icon:
          type: 'div'
          html: pieMarkerFactory.createBackend(model)

  setDataOptions = (data, optionsFormatter) ->
    _.each data, (model,k) ->
      optionsFormatter(model, k)
    data

  setMarkerNotesDataOptions = (data) ->
    setDataOptions(data, MLS.setMarkerNotesOptions)

  setCurrentLocationMarkerOptions = (position) ->
    return {} unless position
    # So posiiton used to be position.latitude or longitude, but now it is in the field coords
    # so we account for both just incase
    # https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition
    # if we have a problem here then it is browser related
    latitude = longitude = null

    if !position.coords?
      {latitude, longitude} = position
    else
      {latitude, longitude} = position.coords

    if !latitude? || !longitude?
      throw new Error("latitude or longitude invalid: latitude: #{latitude}, longitude: #{longitude}")
    #important for the clusterer css a div must have child span
    coordinates: [longitude, latitude]
    type: 'Point'
    markerType: 'currentLocation'
    icon:
      type: 'div'
      html: currentLocationMarkerTemplate()


  #public
  {
    Parcels
    MLS
    isVisible
    setDataOptions
    setMarkerNotesDataOptions
    setCurrentLocationMarkerOptions
  }
