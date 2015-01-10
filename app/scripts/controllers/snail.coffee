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
  'RenderPdfBlob'.ourNs(), 'documentTemplates'.ourNs(), 'MainOptions'.ourNs(),
  ($scope, $rootScope, $location, $http, $sce, $timeout, $modal,
   RenderPdfBlob, documentTemplates, MainOptions) ->
    
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
      from: {}
      style:
        signature: 'print font 3'
        templateId: null
    form = $scope.form

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
          $rootScope.loadingCount--
      if renderPromise
        # replace the existing rendering call
        $timeout.cancel(renderPromise)
        renderPromise = null
      else
        # create a new one
        $rootScope.loadingCount++
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
app.run ["$rootScope", '$location', '$timeout', 'events'.ourNs(), ($rootScope, $location, $timeout, Events) ->
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
]
