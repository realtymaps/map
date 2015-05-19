app = require '../app.coffee'
fonts = require "../../../../common/documentTemplates/signature-fonts/index.coffee"
frontendRoutes = require '../../../../common/config/routes.frontend.coffee'
pdfUtils = require "../../../../common/utils/util.pdf.coffee"


setWatch = null
clearWatch = null
renderPromise = null
rendered = false
data =
  snailData: {}
  property: null
_setContextValues = null

module.exports = app.controller 'rmapsSnailCtrl',
  ($scope, $rootScope, $location, $http, $sce, $timeout, $modal,
   rmapsRenderPdfBlob, rmapsdocumentTemplates, rmapsMainOptions, rmapsSpinner) ->

    $scope.data = data
    $scope.rmapsdocumentTemplates = rmapsdocumentTemplates
    $scope.fonts = fonts
    $scope.placeholderValues =
      from:
        name: "Realtor's Name"
        address_line1: "Real Estate Brokerage"
        address_line2: "Realtor's Street Address"
        address_city: "Realtor's City"
        address_state: "ST"
        address_zip: "Zipcode"
        phone: "Realtor's Phone Number"
        email: "Realtor's Email Address"
      style: {}
    $scope.formReady = false
    $scope.form =
      # instead of a blank form, use some fake default values for now
      #from: {}
      from:
        name: "Dan Sexton"
        address_line1: "Paradise Realty of Naples"
        address_line2: "201 Goodlette Rd S"
        address_city: "Naples"
        address_state: "FL"
        address_zip: "34102"
        phone: "(239) 877-7853"
        email: "dan@mangrovebaynaples.com"
      style:
        signature: 'print font 3'
        # preselect a template as well for now
        templateId: 'letter.prospecting'
        #templateId: null
    $scope.cancel = () ->
      $location.url(frontendRoutes.map)
    $scope.iframeIndex = 0

    _setContextValues = (index, blob) ->
      $scope["pdfPreviewBlob#{index}"] = $sce.trustAsResourceUrl(blob)
      $scope["templateId#{index}"] = $scope.form.style.templateId
      template = $scope.rmapsdocumentTemplates[$scope["templateId#{index}"]]
      if template
        $scope["width#{index}"] = template.width
        $scope["height#{index}"] = template.height
        $scope["heightRatio#{index}"] = ''+(template.height/template.width*100)+'%'
      else
        $scope["width#{index}"] = 0
        $scope["height#{index}"] = 0
        $scope["heightRatio#{index}"] = '0'

    _setContextValues(0, "about:blank")
    _setContextValues(1, "about:blank")

    $scope.renderError = (reason) ->
      rmapsSpinner.decrementLoadingCount("pdf rendering")

    $scope.finishRender = () ->
      $scope.iframeIndex = ($scope.iframeIndex+1)%2
      rmapsSpinner.decrementLoadingCount("pdf rendering")

    doRender = () ->
      renderPromise = null
      rmapsRenderPdfBlob.toBlobUrl($scope.form.style.templateId, $scope.data.snailData)
      .then (blob) ->
        _setContextValues(($scope.iframeIndex+1)%2, blob)
      , $scope.renderError

    updateBlob = (newValue, oldValue) ->
      if !$scope.form?.style?.templateId
        $scope.formReady = false
        return
      template = $scope.rmapsdocumentTemplates[$scope.form.style.templateId]
      formReady = true
      for prop of $scope.form
        $scope.data.snailData[prop] = _.clone($scope.form[prop])
        for key,formValue of $scope.data.snailData[prop]
          # if any non-optional fields aren't filled in, we're not ready
          if !template.optionalFields?[prop]?[key]
            formReady &&= !!formValue
          $scope.data.snailData[prop][key] = formValue || "{{#{$scope.placeholderValues[prop][key]}}}"
      $scope.formReady = formReady

      if renderPromise
        # replace the existing rendering call
        $timeout.cancel(renderPromise)
        renderPromise = null
      else
        # create a new one
        rmapsSpinner.incrementLoadingCount("pdf rendering")
      renderPromise = $timeout(doRender, rmapsMainOptions.pdfRenderDelay)

    setWatch = () ->
      clearWatch?()
      clearWatch = $scope.$watch 'form', updateBlob, true

    setWatch()

    $scope.getPriceQuote = () ->
      if !$scope.formReady
        return
      $scope.modalControl = {}
      $modal.open
        templateUrl: 'modal-snailPrice.tpl.html'
        controller: 'ModalSnailPriceCtrl'.ns()
        scope: $scope
        keyboard: false
        backdrop: 'static'
        windowClass: 'snail-modal'

    if !$scope.data.property
      # we got here through direct navigation, so we don't have data on a particular property, go to the map
      $location.url frontendRoutes.map
app.run ($rootScope, $location, $timeout, rmapsevents, rmapsSpinner) ->
  initiateSend = (property) ->
    _setContextValues?(0, "about:blank")
    _setContextValues?(1, "about:blank")
    data.property = property
    _.extend(data.snailData, pdfUtils.buildAddresses(property))
    setWatch?()
    $location.url frontendRoutes.snail
  $rootScope.$on rmapsevents.snail.initiateSend, (event, property) -> initiateSend(property)

  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    # if we're leaving the snail state, cancel the watch for performance
    if toState?.url != frontendRoutes.snail
      clearWatch?()
      if renderPromise
        $timeout.cancel(renderPromise)
        renderPromise = null
        rmapsSpinner.decrementLoadingCount("pdf rendering")
