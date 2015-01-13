#TODO This should probably become a controller
app = require '../app.coffee'
qs = require 'qs'

app.service 'FilterManager'.ourNs(), [
  '$rootScope', 'Logger'.ourNs(), 'ParcelEnums'.ourNs()
  ($rootScope, $log, ParcelEnums) ->
    manage: (cb) =>
      filter = null
      if $rootScope.selectedFilters
        selectedFilters = _.clone($rootScope.selectedFilters)
        selectedFilters.status = []
        if (selectedFilters.forSale)
          selectedFilters.status.push(ParcelEnums.status.forSale)
        if (selectedFilters.pending)
          selectedFilters.status.push(ParcelEnums.status.pending)
        if (selectedFilters.sold)
          selectedFilters.status.push(ParcelEnums.status.sold)
        if (selectedFilters.notForSale)
          selectedFilters.status.push(ParcelEnums.status.notForSale)
        delete selectedFilters.forSale
        delete selectedFilters.pending
        delete selectedFilters.sold
        delete selectedFilters.notForSale
        filter = '&' + qs.stringify(selectedFilters)
      cb(filter)
      filter
]
