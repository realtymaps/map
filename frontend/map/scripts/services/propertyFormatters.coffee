_ = require 'lodash'
app = require '../app.coffee'
moment = require 'moment'
numeral = require 'numeral'
require '../services/leafletObjectFetcher.coffee'

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
    rmapsEventConstants
    rmapsFiltersFactory
    rmapsMainOptions
  ) ->
    $log = $log.spawn 'propertyFormatterService'
    _forSaleClass = {}
    _forSaleClass[rmapsParcelEnums.status.sold] = 'sold'
    _forSaleClass[rmapsParcelEnums.status.pending] = 'pending'
    _forSaleClass[rmapsParcelEnums.status.forSale] = 'forsale'
    _forSaleClass[rmapsParcelEnums.status.discontinued] = 'notsale'
    _forSaleClass['saved'] = 'saved'
    _forSaleClass['default'] = ''

    svc =
      google: rmapsGoogleService

      isPinnedResult: (result) ->
        rmapsPropertiesService.isPinnedProperty result?.rm_property_id

      activePin: (result) ->
        if @isPinnedResult(result)
          rmapsMainOptions.map.naming.save.un
        else
          rmapsMainOptions.map.naming.save.present

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

      getStatusClass: (result, showPinned = true) ->
        # $log.debug result.rm_property_id, result.data_source_id, result.status, result.close_date, $rootScope.selectedFilters?.closeDateMin,
        #    $rootScope.selectedFilters?.closeDateMax, $rootScope.selectedFilters?.soldRange
        if !result
          return ''
        if result.savedDetails?.isPinned && showPinned
          return _forSaleClass['saved']
        if result.status != 'sold'
          return _forSaleClass[result.status] || _forSaleClass['default']
        if !result.close_date
          return _forSaleClass[rmapsParcelEnums.status.discontinued]
        if !$rootScope.selectedFilters?.closeDateMin && !$rootScope.selectedFilters?.closeDateMax
          soldRange = rmapsFiltersFactory.values.soldRange[$rootScope.selectedFilters?.soldRange] || '1 year'
          try
            qty = parseInt(soldRange)
            units = soldRange.match(/^\d+ ([a-z])/)[1]
            units = if units == 'm' then 'M' else units
            minDate = moment().subtract(qty, units)
          catch
            return _forSaleClass[rmapsParcelEnums.status.discontinued]
        else
          if $rootScope.selectedFilters?.closeDateMin
            minDate = moment($rootScope.selectedFilters?.closeDateMin)
          if $rootScope.selectedFilters?.closeDateMax
            maxDate = moment($rootScope.selectedFilters?.closeDateMax)

        if minDate?.isAfter(moment(result.close_date))
          return _forSaleClass[rmapsParcelEnums.status.discontinued]
        if maxDate?.isBefore(moment(result.close_date))
          return _forSaleClass[rmapsParcelEnums.status.discontinued]
        return _forSaleClass[rmapsParcelEnums.status.sold]

      getStatusLabelClass: (result, ignorePinned = false) ->
        if !result
          return ''
        return "label-#{@getStatusClass(result, !ignorePinned)}-property"

      getStatusLabel: (result, imageWidth) ->
        if result.status == 'sold'
          if !result.close_date
            return "No Sale Record"
          try
            if imageWidth < 150
              format = 'MM/DD/YY'
            else
              format = 'MMM D, YYYY'
            return "Sold: #{moment(result.close_date).format(format)}"
          catch
            return "No Sold Record"
        else
          return result.status

      showSoldDate: (result) ->
        return result?.status == 'sold' && result?.close_date

      getSqFtPriceLabel: (status) ->
        if (status == 'sold' || status == 'not for sale')
          return 'Sold Price/SqFt'
        else
          return 'Asking Price/SqFt'

      getDaysForSale: (result) ->
        end = moment(result.close_date or result.discontinued_date or moment.utc())
        start = moment(result.creation_date)
        days = end.diff(start, 'days')
        return days

      getDaysOnMarket: (result) ->
        if !result.days_on_market then return null
        if result.status == 'for sale' || result.status == 'pending'
          compensate = moment.utc().diff(result.up_to_date, 'days')
          return result.days_on_market + compensate
        return result.days_on_market

      getCumulativeDaysOnMarket: (result) ->
        if !result.days_on_market_cumulative then return null
        if result.status == 'for sale' || result.status == 'pending'
          compensate = moment.utc().diff(result.up_to_date, 'days')
          return result.days_on_market_cumulative + compensate
        return result.days_on_market_cumulative

      getSqFtPrice: (result) ->
        return if !result.price || !result.sqft_finished
        numeral(result.price / result.sqft_finished).format('$0,0.00')

      processDisclaimerTextMacros: (result) ->
        # disclaimer text macros can be any keys that exist on the property result
        result?.disclaimer_text?.replace /\{\{(\w+)\}\}/g, (test, match) ->
          if match of result
            if match in ["up_to_date", "created_date", "discontinued_date"] # format dates
              return new Date(result[match]).toLocaleDateString()
            return result[match]
          return test

    return _.extend(svc, rmapsFormattersService.Common)
