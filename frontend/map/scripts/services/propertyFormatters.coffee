app = require '../app.coffee'
Point = require('../../../../common/utils/util.geometries.coffee').Point

sprintf = require('sprintf-js').sprintf
require '../services/leafletObjectFetcher.coffee'

app.service 'rmapsPropertyFactoryFormatterService', ($rootScope, $timeout, $filter, $log, $state, $location, rmapsParcelEnums,
  rmapsGoogleService, rmapsPropertiesService, rmapsFormattersService, uiGmapGmapUtil, rmapsevents,
  rmapsLeafletObjectFetcherFactory, rmapsMainOptions, rmapsZoomLevelService) ->

  leafletDataMainMap = new rmapsLeafletObjectFetcherFactory('mainMap')
  limits = rmapsMainOptions.map

  _forSaleClass = {}
  _forSaleClass[rmapsParcelEnums.status.sold] = 'sold'
  _forSaleClass[rmapsParcelEnums.status.pending] = 'pending'
  _forSaleClass[rmapsParcelEnums.status.forSale] = 'forsale'
  _forSaleClass[rmapsParcelEnums.status.notForSale] = 'notsale'
  _forSaleClass['saved'] = 'saved'
  _forSaleClass['default'] = ''

  _statusLabelClass = {}
  _statusLabelClass[rmapsParcelEnums.status.sold] = 'label-sold-property'
  _statusLabelClass[rmapsParcelEnums.status.pending] = 'label-pending-property'
  _statusLabelClass[rmapsParcelEnums.status.forSale] = 'label-sale-property'
  _statusLabelClass[rmapsParcelEnums.status.notForSale] = 'label-notsale-property'
  _statusLabelClass['saved'] = 'label-saved-property'
  _statusLabelClass['default'] = ''

  class PropertyFormatter

    constructor: () ->
      _.extend @, rmapsFormattersService.Common
      _.extend @, google: rmapsGoogleService

    isSavedResult:(result) ->
      result?.savedDetails?.isSaved == true

    isFavoriteResult:(result) ->
      result?.savedDetails?.isFavorite == true

    getCurrentOwnersTitle: (result) =>
      title = 'result-property-hovered'
      if @hasMultipleOwners(result)
        title += 's'
      title

    hasMultipleOwners: (result) ->
      if result.owner_name2? and result.owner_name?
        return true
      return false

    getForSaleClass: (result, showSaved = true) ->
      return unless result
      soldClass = _forSaleClass['saved'] if showSaved and result.savedDetails?.isSaved
      soldClass or _forSaleClass[result.rm_status] or _forSaleClass['default']

    getStatusLabelClass: (result, ignoreSavedStatus=false) ->
      return unless result
      soldClass = _statusLabelClass['saved'] if result.savedDetails?.isSaved && !ignoreSavedStatus
      return soldClass or _statusLabelClass[result.rm_status] or _statusLabelClass['default']

    showSoldDate: (result) ->
      return false unless result
      return (result?.rm_status=='recently sold'||result.rm_status=='not for sale') && result.close_date

    sendSnail: (result) ->
      $rootScope.$emit rmapsevents.snail.initiateSend, result

    getPriceLabel: (status) ->
      if (status =='recently sold'|| status=='not for sale')
        label = ''
      else
        label = 'asking:'
      return label

    getCityStateZip: (model, owner=false) ->
      if !model?
        return ''
      prefix = if owner then 'owner_' else ''
      csz = "#{model[prefix+"city"]}"
      if model[prefix+'state']
        csz += ", #{model[prefix+"state"]}"
      if model[prefix+'zip']
        csz += " #{model[prefix+"zip"]}"
      return csz

    showListingData: (model) ->
      return false if not model
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
