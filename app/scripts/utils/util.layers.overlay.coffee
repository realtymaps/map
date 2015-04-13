module.exports =
  filterSummary: # can be price and poly (consider renaming)
    name: 'Homes Detail'
    type: "markercluster"
    visible: true
    layerOptions:
      chunkedLoading: true
      showCoverageOnHover: false
      removeOutsideVisibleBounds: true

  backendPriceCluster:
    name: 'Price Cluster'
    type: 'group'
    visible: true

  addresses:
    name: 'Addresses'
    type: 'group'
    visible: true
