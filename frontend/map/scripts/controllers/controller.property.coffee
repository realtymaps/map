app = require '../app.coffee'
_ = require 'lodash'
moment = require 'moment'

app.controller 'rmapsPropertyCtrl',
  (
    $scope
    $rootScope
    $stateParams
    $log
    $modal
    rmapsPropertiesService
    rmapsFormattersService
    rmapsResultsFormatterService
    rmapsPropertyFormatterService
    rmapsGoogleService
    rmapsMailCampaignService
    rmapsFiltersFactory
    $http
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
      {name: 'priorListings', label: 'Prior Listings', subscriber: 'subscriber_groups'}
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

    $scope.showDMCA = (mls) ->
      $modal.open
        template: require('../../html/views/templates/modal-dmca.tpl.jade')()
        controller: 'rmapsModalInstanceCtrl'
        resolve: model: -> mls

    getPropertyDetail = (propertyId) ->
      rmapsPropertiesService.getPropertyDetail(null, {rm_property_id: propertyId }, 'all', true)
      .then (property) ->
        $scope.selectedResult = property

        $scope.dataSources = (property.mls||[]).concat(property.county||[])

        # Temporary mock data
        if property.mls?[0]
          property.mls[0].subscriber_groups.priorListings = [
            {
              data_source_type: 'mls'
              date: new Date()
              event: 'Terminated'
              price: 2000000
              listing_agent: 'A. Realtor'
              sqft_finished: 1890
              acres: 1.2
              year_built: 1950
              days_on_market: 150
              subscriber_groups: _.cloneDeep property.mls[0].subscriber_groups
              shared_groups: _.cloneDeep property.mls[0].shared_groups
            }
          ]

        # Sets up Deed, Mortage and Listing history arrays with extra data split off (for ng-repeat)
        for source in $scope.dataSources
          for history in ['deedHistory', 'mortgageHistory', 'priorListings']
            if source?.subscriber_groups?[history]
              historyExtra = []
              for entry in source.subscriber_groups[history]
                entry.extra = _.clone(entry)
                historyExtra.push(entry, entry.extra)
              source.subscriber_groups["#{history}Extra"] = historyExtra

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
        catch error
          return label: "Not Sold", class: 'notsale'
      else
        return label: property.status, class: $scope.formatters.property.getForSaleClass(property, false)

    $scope.showPVA = (rm_property_id) ->
      splits = rm_property_id.split('_')
      fips = splits[0]
      apn = splits[1]
      # this should probably be changed to somehow be based on our actual CDN config, but it works for now
      cdnNum = (fips % 2)+1
      pvaUrl = "//prodpull#{cdnNum}.realtymapsterllc.netdna-cdn.com/api/properties/pva/#{fips}"
      $http.get(pvaUrl)
      .then ({data}) ->
        url = data.url.replace("{{_APN_}}", apn)
        if data.options?.post
          pvaForm = document.createElement("form")
          windowName = window.name+(new Date().getTime())
          pvaForm.target = windowName
          pvaForm.method = "POST"
          pvaForm.action = url

          for name, value of data.options.post
            newInput = document.createElement("input")
            newInput.type = "hidden"
            newInput.name = name
            newInput.value = value.replace("{{_APN_}}", apn)
            pvaForm.appendChild(newInput)

          document.body.appendChild(pvaForm)
          if window.open('', windowName)
            pvaForm.submit()
          else
            alert("Please enable popups on this page")
        else
          window.open(url)

      return false

    getPropertyDetail $stateParams.id