#TODO This should probably become a controller
app = require '../app.coffee'
qs = require 'qs'

app.service 'FilterManager'.ourNs(), [
  '$rootScope', 'Logger'.ourNs(), 'ParcelEnums'.ourNs()
  ($rootScope, $log, ParcelEnums) ->

    cleanFilters = (filters) ->
      #remove all null, zero, and empty string values so we don't send them
      _.each filters, (v,k) ->
        if !v && v != false
          delete filters[k]

    manage: (cb) =>
      filter = null
      if $rootScope.selectedFilters
        selectedFilters = _.clone($rootScope.selectedFilters)
        cleanFilters(selectedFilters)
        selectedFilters.status = []
        if (selectedFilters.forSale)
          selectedFilters.status.push(ParcelEnums.status.forSale)
        if (selectedFilters.pending)
          selectedFilters.status.push(ParcelEnums.status.pending)
        if (selectedFilters.sold)
          selectedFilters.status.push(ParcelEnums.status.sold)
        if (selectedFilters.notForSale)
          selectedFilters.status.push(ParcelEnums.status.notForSale)
        if (selectedFilters.saved)
          selectedFilters.status.push(ParcelEnums.status.saved)
        delete selectedFilters.forSale
        delete selectedFilters.pending
        delete selectedFilters.sold
        delete selectedFilters.notForSale
        delete selectedFilters.saved

        filter = '&' + qs.stringify(selectedFilters)
      cb(filter)
      filter
]
