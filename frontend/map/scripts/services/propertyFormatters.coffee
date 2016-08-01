###globals _###
app = require '../app.coffee'
require '../services/leafletObjectFetcher.coffee'

app.service 'rmapsPropertyFormatterService', ($rootScope, $timeout, $filter, $log, $state, $location, rmapsParcelEnums,
  rmapsGoogleService, rmapsPropertiesService, rmapsFormattersService, uiGmapGmapUtil, rmapsEventConstants) ->

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
        soldClass = _forSaleClass['saved']
      return soldClass || _forSaleClass[result.status] || _forSaleClass['default']

    getStatusLabelClass: (result, ignorePinned = false) ->
      if !result
        return ''
      return "label-#{@getForSaleClass(result, !ignorePinned)}-property"

    showSoldDate: (result) ->
      return false unless result
      status = result?.status
      return (status=='sold'||status=='not for sale') && result.close_date

    sendSnail: (result) ->
      $rootScope.$emit rmapsEventConstants.snail.initiateSend, result

    getPriceLabel: (status) ->
      if (status =='sold'|| status=='not for sale')
        label = ''
      else
        label = 'asking:'
      return label

    showListingData: (model) ->
      if !model || model.data_source_type != 'mls'
        return false
      model.listing_age!=null || model.mls_close_date || model.original_price || model.mls_close_price

    showSalesData: (model) ->
      return false if not model
      model.mortgage_amount || model.mortgage_date || @showIfDifferentFrom(model, 'sale', 'mls_close') || @showIfDifferentFrom(model, 'prior_sale', 'mls_close')

    showIfDifferentFrom: (model, prefix, differentFromPrefix) ->
      return false if !model || !prefix || !differentFromPrefix
      prefix += '_'
      differentFromPrefix += '_'
      # differing prices or >= 30 days difference in sale date
      if (model[prefix+'date'] && !model[differentFromPrefix+'date']) || model[prefix+'price'] != model[differentFromPrefix+'price']
        return true
      if !model[prefix+'date']
        return false
      millis1 = new Date(model[differentFromPrefix+'date'].toLocaleString()).getTime()
      millis2 = new Date(model[prefix+'date'].toLocaleString()).getTime()
      return Math.abs(millis1-millis2) > 30*86400000
