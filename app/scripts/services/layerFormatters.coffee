app = require '../app.coffee'

sprintf = require('sprintf-js').sprintf
numeral = require 'numeral'
casing = require 'case'

app.service 'LayerFormatters'.ourNs(), [
  'Logger'.ourNs(), 'ParcelEnums'.ourNs(), "uiGmapGmapUtil", 'Properties'.ourNs(),
  ($log, ParcelEnums, uiGmapUtil, Properties) ->
    filterSummaryHash = {}
    propertySaveYellow = '#EFEE50'
    colors = {}
    colors[ParcelEnums.status.sold] = '#2c8aa7'
    colors[ParcelEnums.status.pending] = '#d48c0e'
    colors[ParcelEnums.status.forSale] = '#2fa02c'
    colors['default'] = 'rgba(105, 245, 233, 0.08)' #or '#7e847f'?

    markersIcon = {}
    markersIcon[ParcelEnums.status.sold] = '../assets/map_marker_out_pink_64.png'
    markersIcon[ParcelEnums.status.pending] = '../assets/map_marker_out_azure_64.png'
    markersIcon[ParcelEnums.status.forSale] = '../assets/map_marker_out_green_64.png'
    markersIcon['default'] = ''

    markerContentTemplate = '<h4><span class="label label-%s">%s</span></h4>'
    markersBSLabel = {}
    markersBSLabel[ParcelEnums.status.sold] = 'danger'
    markersBSLabel[ParcelEnums.status.pending] = 'warning'
    markersBSLabel[ParcelEnums.status.forSale] = 'success'
    markersBSLabel['default'] = 'info'

    formatMarkerContent = (label, content) ->
      sprintf markerContentTemplate, label, content

    formatStatusMarkerContent = (status, content) ->
      formatMarkerContent markersBSLabel[status] or markersBSLabel['default'], content

    getPixelFromLatLng = (latLng, map) ->
      point = map.getProjection().fromLatLngToPoint(latLng)
      point

    getSavedColorProperty = (model) ->
      props = Properties.getSavedProperties()
      prop = props[model.rm_property_id] if _.has props, model.rm_property_id
      if not prop or not prop.isSaved
        return
      propertySaveYellow

    getWindowOffset = (map, mls, width = 290) ->
      return if not mls or not map
      center = getPixelFromLatLng(map.getCenter(), map)
      point = getPixelFromLatLng(uiGmapUtil.getCoords(mls.geom_point_json), map)
      quadrant = ''
      quadrant += (if (point.y > center.y) then "b" else "t")
      quadrant += (if (point.x < center.x) then "l" else "r")
      if quadrant is "tr"
        offset = new google.maps.Size(-1 * width, 45)
      else if quadrant is "tl"
        offset = new google.maps.Size(0, 45)
      else if quadrant is "br"
        offset = new google.maps.Size(-1 * width, -250)
      else offset = new google.maps.Size(25, -250)  if quadrant is "bl"
      offset

    Parcels:
      fill: (parcel) ->
        return {} unless parcel
        model = parcel.model
        maybeSavedColor = getSavedColorProperty(model)
        unless maybeSavedColor
          model = if _.has filterSummaryHash, model.rm_property_id then filterSummaryHash[model.rm_property_id] else model
        color:  maybeSavedColor or colors[model.rm_status] or colors['default']
        opacity: '.65'

      labelFromStreetNum: (parcel) ->
        return {} unless parcel
        icon: ' '
        labelContent: "<h5>#{parcel.street_address_num}</h5>"
        labelAnchor: "20 10"
        zIndex: 0

    MLS:
      markerOptionsFromForSale: (mls) ->
        return {} unless mls
        formattedPrice = casing.upper numeral(mls.price).format('0.00a'), '.'
        ret =
          icon: markersIcon[mls.rm_status] or markersIcon['default']
          labelContent: formatStatusMarkerContent mls.rm_status, formattedPrice
          labelAnchor: "30 100"
          zIndex: 1
        ret

      getWindowOffset:getWindowOffset

    updateFilterSummaryHash: (hash) ->
      filterSummaryHash = hash
]
