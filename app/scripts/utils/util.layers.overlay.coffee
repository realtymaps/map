pieUtil = require './util.piechart.coffee'

module.exports =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: "markercluster"
    visible: true
    layerOptions:
      maxClusterRadius: 100
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true
      iconCreateFunction: pieUtil.pieCreateFunction

  backendPriceCluster:
    name: 'Price Cluster'
    type: 'group'
    visible: true

  addresses:
    name: 'Addresses'
    type: 'group'
    visible: true
