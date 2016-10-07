###globals _###
app = require '../app.coffee'
require '../services/leafletObjectFetcher.coffee'
moment = require 'moment'

app.service 'rmapsPropertyFormatterService',
  (
    $rootScope
    $timeout
    $filter
    $log
    $state
    $location
    rmapsParcelEnums
    rmapsGoogleService
    rmapsPropertiesService
    rmapsFormattersService
    uiGmapGmapUtil
    rmapsEventConstants
  ) ->

  _forSaleClass = {}
  _forSaleClass[rmapsParcelEnums.status.sold] = 'sold'
  _forSaleClass[rmapsParcelEnums.status.pending] = 'pending'
  _forSaleClass[rmapsParcelEnums.status.forSale] = 'forsale'
  _forSaleClass[rmapsParcelEnums.status.discontinued] = 'notsale'
  _forSaleClass['saved'] = 'saved'
  _forSaleClass['default'] = ''

  class PropertyFormatter

    constructor: () ->
      _.extend @, rmapsFormattersService.Common
      _.extend @, google: rmapsGoogleService

    isPinnedResult: (result) ->
      rmapsPropertiesService.isPinnedProperty result?.rm_property_id

    isFavoriteResult: (result) ->
      rmapsPropertiesService.isFavoriteProperty result?.rm_property_id

    getCurrentOwnersTitle: (result) =>
      title = result?.owner_title
      if title and @hasMultipleOwners(result)
        title += 's'
      title

    hasMultipleOwners: (result) ->
      if result.owner_name_2? and result.owner_name?
        return true
      return false

    getForSaleClass: (result, showPinned = true) ->
      if !result
        return ''
      if result.savedDetails?.isPinned && showPinned
        return _forSaleClass['saved']
      if result.status == 'sold'
        soldRange = '1 year' # rmapsFiltersFactory.values.soldRange[$rootScope.selectedFilters?.soldRange] || '1 year'
        try
          qty = parseInt(soldRange)
          units = soldRange.match(/^\d+ ([a-z])/)[1]
          units = if units == 'm' then 'M' else units
          if moment().subtract(qty, units).isBefore(moment(result.close_date))
            return _forSaleClass.sold
          else
            return _forSaleClass.notsale
        catch error
          return _forSaleClass.notsale
      return _forSaleClass[result.status] || _forSaleClass['default']

    getStatusLabelClass: (result, ignorePinned = false) ->
      if !result
        return ''
      return "label-#{@getForSaleClass(result, !ignorePinned)}-property"

    getStatusLabel: (result) ->
      if result.status == 'sold'
        soldRange = '1 year' # rmapsFiltersFactory.values.soldRange[$rootScope.selectedFilters?.soldRange] || '1 year'
        try
          qty = parseInt(soldRange)
          units = soldRange.match(/^\d+ ([a-z])/)[1]
          units = if units == 'm' then 'M' else units
          if moment().subtract(qty, units).isBefore(moment(result.close_date))
            return "Sold within #{soldRange}"
          else
            return "Not Sold within #{soldRange}"
        catch error
          return "Not Sold"
      else
        return result.status

    showSoldDate: (result) ->
      return result?.status == 'sold' && result?.close_date

    sendSnail: (result) ->
      $rootScope.$emit rmapsEventConstants.snail.initiateSend, result

    getPriceLabel: (status) ->
      if (status =='sold'|| status=='not for sale')
        label = ''
      else
        label = 'asking:'
      return label
