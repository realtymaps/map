#TODO This should probably become a controller
app = require '../app.coffee'
qs = require 'qs'

app.service 'rmapsFilterManager', ($rootScope, $log, rmapsParcelEnums) ->

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
        selectedFilters.status.push(rmapsParcelEnums.status.forSale)
      if (selectedFilters.pending)
        selectedFilters.status.push(rmapsParcelEnums.status.pending)
      if (selectedFilters.sold)
        selectedFilters.status.push(rmapsParcelEnums.status.sold)
      if (selectedFilters.notForSale)
        selectedFilters.status.push(rmapsParcelEnums.status.notForSale)
      delete selectedFilters.forSale
      delete selectedFilters.pending
      delete selectedFilters.sold
      delete selectedFilters.notForSale

      filter = qs.stringify(selectedFilters)
      if filter.length > 0
        filter = '&' + filter
      cb(filter)
