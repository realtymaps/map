app = require '../app.coffee'
fonts = require "../../../common/documentTemplates/signature-fonts/index.coffee"
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
pdfUtils = require "../../../common/utils/util.pdf.coffee"


setWatch = null
clearWatch = null
renderPromise = null
rendered = false
data = 
  snailData: {}
  property: null

module.exports = app.controller 'SnailCtrl'.ourNs(), [
  '$scope', '$rootScope', '$location', '$http', '$sce', '$timeout', '$modal',
  'RenderPdfBlob'.ourNs(), 'documentTemplates'.ourNs(), 'MainOptions'.ourNs(), 'Spinner'.ourNs(),
  ($scope, $rootScope, $location, $http, $sce, $timeout, $modal,
   RenderPdfBlob, documentTemplates, MainOptions, Spinner) ->
    
    $scope.data = data
    $scope.documentTemplates = documentTemplates
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
    $scope.pdfPreviewBlob = $sce.trustAsResourceUrl("about:blank")
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
    $scope.getHeightRatio = () ->
      template = $scope.documentTemplates[$scope.form.style.templateId]
      ''+(template.height/template.width*100)+'%'

    updateBlob = (newValue, oldValue) ->
      if rendered
        $scope.pdfPreviewBlob = $sce.trustAsResourceUrl("about:blank")
        rendered = false
      if !$scope.form?.style?.templateId
        $scope.formReady = false
        return
      formReady = true
      for prop of $scope.form
        $scope.data.snailData[prop] = _.clone($scope.form[prop])
        _.extend $scope.data.snailData[prop], $scope.placeholderValues[prop], (formValue, placeholderValue) ->
          # if any fields aren't filled in, we're not ready
          formReady &&= !!formValue
          return formValue || "{{#{placeholderValue}}}"
      $scope.formReady = formReady
        
      doRender = () ->
        renderPromise = null
        RenderPdfBlob.toBlobUrl($scope.form.style.templateId, $scope.data.snailData)
        .then (blob) ->
          $scope.pdfPreviewBlob = $sce.trustAsResourceUrl(blob)
          rendered = true
          Spinner.decrementLoadingCount("pdf rendering")
        , () ->
          Spinner.decrementLoadingCount("pdf rendering")
      if renderPromise
        # replace the existing rendering call
        $timeout.cancel(renderPromise)
        renderPromise = null
      else
        # create a new one
        Spinner.incrementLoadingCount("pdf rendering")
      renderPromise = $timeout(doRender, MainOptions.pdfRenderDelay)
    
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
        controller: 'ModalSnailPriceCtrl'.ourNs()
        scope: $scope
        keyboard: false
        backdrop: 'static'
        windowClass: 'snail-modal'
    
    if !$scope.data.property
      # we got here through direct navigation, so we don't have data on a particular property, go to the map
      $location.url frontendRoutes.map
]
app.run ["$rootScope", '$location', '$timeout', 'events'.ourNs(), 'Spinner'.ourNs(), ($rootScope, $location, $timeout, Events, Spinner) ->
  initiateSend = (property) ->
    data.property = property
    _.extend(data.snailData, pdfUtils.buildAddresses(property))
    setWatch?()
    $location.url frontendRoutes.snail
  $rootScope.$on Events.snail.initiateSend, (event, property) -> initiateSend(property)

  $rootScope.$on "$stateChangeStart", (event, toState, toParams, fromState, fromParams) ->
    # if we're leaving the snail state, cancel the watch for performance
    if toState?.url != frontendRoutes.snail
      clearWatch?()
      if renderPromise
        $timeout.cancel(renderPromise)
        renderPromise = null
        Spinner.decrementLoadingCount("pdf rendering")
]
