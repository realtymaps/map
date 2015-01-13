app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.service 'LayerFormatters'.ourNs(), [
  'Logger'.ourNs(), 'ParcelEnums'.ourNs(), "uiGmapGmapUtil",
  ($log, ParcelEnums, uiGmapUtil) ->

    saveColor = '#F3F315'
    mouseOverColor = 'rgba(153, 152, 149, 0.79)'

    filterSummaryHash = {}

    markerContentTemplate = '<h4><span class="label label-%s">%s</span></h4>'
    markersBSLabel = {}
    markersBSLabel[ParcelEnums.status.sold] = 'sold-property'
    markersBSLabel[ParcelEnums.status.pending] = 'pending-property'
    markersBSLabel[ParcelEnums.status.forSale] = 'sale-property'
    markersBSLabel['saved'] = 'saved-property'
    markersBSLabel['hovered'] = 'hovered-property'
    markersBSLabel['default'] = 'info'

    formatMarkerContent = (label, content) ->
      sprintf markerContentTemplate, label, content

    formatStatusMarkerContent = (status, content) ->
      formatMarkerContent markersBSLabel[status] or markersBSLabel['default'], content

    getPixelFromLatLng = (latLng, map) ->
      point = map.getProjection().fromLatLngToPoint(latLng)
      point

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

    getSavedColorProperty = (model) ->
      if not model.savedDetails or not model.savedDetails.isSaved
        return
      saveColor

    getMouseOver = (model, toReturn = mouseOverColor) ->
      return if not model or not model.isMousedOver
      return toReturn

    parcels = do ->
      colors = {}
      colors[ParcelEnums.status.sold] = '#ff4a4a'
      colors[ParcelEnums.status.pending] = '#6C3DCA'
      colors[ParcelEnums.status.forSale] = '#1fde12'
      colors['default'] = 'rgba(105, 245, 233, 0.00)' #or '#7e847f'?

      gFillColor = (color) ->
        fillColor: color

      # fillOpts is unique to uiGmap since we are interacting directly with the gPoly we need the real options
      gOptsFromUiGmapFill = (fillOpts) ->
        fillColor: fillOpts.color
        fillOpacity: fillOpts.opacity

      fillColorFromState = (parcel) ->
        return {} unless parcel
        model = parcel.model
        maybeSavedColor = getSavedColorProperty(model)
        unless maybeSavedColor
          model = if _.has(filterSummaryHash, model.rm_property_id) then filterSummaryHash[model.rm_property_id] else model
        getMouseOver(model) or maybeSavedColor or colors[model.rm_status]

      fill = (parcel) ->
        color: fillColorFromState(parcel) or colors['default']
        opacity: '.70'

      labelFromStreetNum = (parcel) ->
        return {} unless parcel
        icon: ' '
        labelContent: "<span class='address-label'>#{String.orNA parcel.street_address_num}</span>"
        labelAnchor: "10 10"
        zIndex: 1
        markerType: "streetNum"

      fill: fill
      labelFromStreetNum: labelFromStreetNum

      optionsFromFill: (parcel) ->
        gOptsFromUiGmapFill fill(parcel)

      mouseOverOptions: (parcel) ->
        fillColorFromState(parcel) or gFillColor(mouseOverColor)

    mls = do ->
      markerOptionsFromForSale: (mls) ->
        return {} unless mls
        formattedPrice = if not mls.price then String.orNA(mls.price) else casing.upper numeral(mls.price).format('0.0a'), '.'
        savedStatus = 'saved' if getSavedColorProperty(mls)
        ret =
          icon: ' '
          labelContent: formatStatusMarkerContent(mls.isMousedOver or savedStatus or mls.rm_status, formattedPrice)
          labelAnchor: "30 50"
          zIndex: 2
          markerType: "price"
        ret

      getWindowOffset: getWindowOffset

    #public
    Parcels: parcels
    MLS: mls
    updateFilterSummaryHash: (hash) ->
      filterSummaryHash = hash


]
