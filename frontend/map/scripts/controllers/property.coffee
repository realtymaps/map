app = require '../app.coffee'
_ = require 'lodash'
moment = require 'moment'

app.controller 'rmapsPropertyCtrl',
  (
    $scope,
    $rootScope,
    $stateParams,
    $log,
    $modal,
    rmapsPropertiesService,
    rmapsFormattersService,
    rmapsResultsFormatterService,
    rmapsPropertyFormatterService,
    rmapsGoogleService,
    rmapsMailCampaignService,
    rmapsFiltersFactory
  ) ->

    $log = $log.spawn 'rmapsPropertyCtrl'
    $log.debug "rmapsPropertyCtrl for id: #{$stateParams.id}"

    _.extend $scope, rmapsFormattersService.Common,

    $scope.google = rmapsGoogleService

    $scope.getMail = () ->
      rmapsMailCampaignService.getMail $stateParams.id

    $scope.tab = selected: ''

    $scope.formatters =
      results: new rmapsResultsFormatterService scope: $scope
      property: new rmapsPropertyFormatterService

    _.merge @scope,
      streetViewPanorama:
        status: 'OK'
      control: {}

    $scope.getLabel = (group, property) ->
      if (typeof group.label) == 'string'
        return group.label
      return group.label[property.data_source_type]

    $scope.groups = [
      {name: 'general', label: 'General Info', subscriber: 'shared_groups'}
      {name: 'details', label: 'Details', subscriber: 'shared_groups'}
      {name: 'listing', label: 'Listing', subscriber: 'shared_groups'}
      {name: 'dimensions', label: 'Room Dimensions', subscriber: 'shared_groups'}
      {name: 'lot', label: 'Lot', subscriber: 'shared_groups'}
      {name: 'location', label: {mls: 'Location & Schools', county: 'Location'}, subscriber: 'shared_groups'}
      {name: 'building', label: 'Building', subscriber: 'shared_groups'}
      {name: 'restrictions', label: 'Taxes, Fees and Restrictions', subscriber: 'shared_groups'}
      {name: 'contacts', label: 'Listing Contacts', subscriber: 'subscriber_groups'}
      {name: 'realtor', label: 'Listing Details', subscriber: 'subscriber_groups'}
      {name: 'sale', label: 'Sale Details', subscriber: 'subscriber_groups',}
      {name: 'owner', label: 'Owner', subscriber: 'subscriber_groups'}
      {name: 'deed', label: 'Deed', subscriber: 'subscriber_groups'}
      {name: 'deedHistory', label: 'Deed History', subscriber: 'subscriber_groups'}
      {name: 'mortgage', label: 'Mortgage', subscriber: 'subscriber_groups'}
      {name: 'mortgageHistory', label: 'Mortgage History', subscriber: 'subscriber_groups'}
    ]

    $scope.previewLetter = (mail) ->
      $modal.open
        template: require('../../html/views/templates/modal-mailPreview.tpl.jade')()
        controller: 'rmapsReviewPreviewCtrl'
        openedClass: 'preview-mail-opened'
        windowClass: 'preview-mail-window'
        windowTopClass: 'preview-mail-windowTop'
        resolve:
          template: () ->
            pdf: mail.lob.url
            title: 'Mail Review'

    $scope.showDCMA = (mls) ->
      $modal.open
        template: require('../../html/views/templates/modal-dmca.tpl.jade')()
        controller: 'rmapsModalInstanceCtrl'
        resolve: model: -> mls

    getPropertyDetail = (propertyId) ->
      rmapsPropertiesService.getPropertyDetail(null, {rm_property_id: propertyId }, 'all', false)
      .then (property) ->
        $scope.selectedResult = property

        # Sets up Deed and Mortage history array with extra data split off (for ng-repeat)
        for county in property.county
          for history in ['deedHistory', 'mortgageHistory']
            if county?.subscriber_groups?[history]
              historyExtra = []
              for entry in county.subscriber_groups[history]
                entry.extra = _.clone(entry)
                historyExtra.push(entry, entry.extra)
              county.subscriber_groups["#{history}Extra"] = historyExtra

        $scope.dataSources = [].concat(property.mls||[]).concat(property.county||[])
        $scope.tab.selected = (property.mls?[0] || property.county?[0])?.data_source_id || 'raw'

    $scope.getStatus = (property) ->
      if property.status == 'sold'
        soldRange = rmapsFiltersFactory.values.soldRange[$rootScope.selectedFilters?.soldRange] || '1 year'
        try
          qty = parseInt(soldRange)
          units = soldRange.match(/^\d+ ([a-z])/)[1]
          units = if units == 'm' then 'M' else units
          if moment().subtract(qty, units).isBefore(moment(property.close_date))
            return label: "Sold within #{soldRange}", class: 'sold'
          else
            return label: "Not Sold witin #{soldRange}", class: 'notsale'
        catch ex
          return label: "Not Sold", class: 'notsale'
      else
        return label: property.status, class: $scope.formatters.property.getForSaleClass(property, false)

    getPropertyDetail $stateParams.id
