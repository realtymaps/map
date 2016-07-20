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

    $scope.groups = [
      name: 'general', label: 'General Info', subscriber: 'shared_groups'
     ,
      name: 'details', label: 'Details', subscriber: 'shared_groups'
     ,
      name: 'listing', label: 'Listing', subscriber: 'shared_groups'
     ,
      name: 'building', label: 'Building', subscriber: 'shared_groups'
     ,
      name: 'dimensions', label: 'Room Dimensions', subscriber: 'shared_groups'
     ,
      name: 'lot', label: 'Lot', subscriber: 'shared_groups'
     ,
      name: 'location', label: 'Location & Schools', subscriber: 'shared_groups'
     ,
      name: 'restrictions', label: 'Taxes, Fees and Restrictions', subscriber: 'shared_groups'
     ,
      name: 'contacts', label: 'Listing Contacts', subscriber: 'subscriber_groups'
     ,
      name: 'realtor', label: 'Listing Details', subscriber: 'subscriber_groups'
     ,
      name: 'sale', label: 'Sale Details', subscriber: 'subscriber_groups',
    ,
      name: 'owner', label: 'Owner', subscriber: 'subscriber_groups'
     ,
      name: 'deed', label: 'Deed', subscriber: 'subscriber_groups'
     ,
      name: 'mortgage', label: 'Mortgage', subscriber: 'subscriber_groups'
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

    $scope.showPVA = (rm_property_id, post) ->
      # TODO: call backend service with rm_property_id to get PVA url
      # $http.get("#{backendRoutes.property.pva}/#{rm_property_id}")
      # .then (pvaPage) ->
      # Mock response
      pvaPage =
        url: "http://www.collierappraiser.com/Main_Search/RecordDetail.html?FolioID=#{rm_property_id.slice(6,17)}"
        post: post

      if !_.isEmpty(pvaPage.post)
        pvaForm = document.createElement("form")
        windowName = window.name+(new Date().getTime())
        pvaForm.target = windowName
        pvaForm.method = "POST"
        pvaForm.action = pvaPage.url

        for name, value of pvaPage.post
          newInput = document.createElement("input")
          newInput.type = "hidden"
          newInput.name = name
          newInput.value = value
          pvaForm.appendChild(newInput)

        document.body.appendChild(pvaForm)
        if child = window.open('', windowName)
          pvaForm.submit()
        else
          alert("Please enable popups on this page")

      else
        window.open(pvaPage.url)

      return false

    getPropertyDetail $stateParams.id
