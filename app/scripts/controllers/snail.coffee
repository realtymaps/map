app = require '../app.coffee'
frontendRoutes = require '../../../common/config/routes.frontend.coffee'
backendRoutes = require '../../../common/config/routes.backend.coffee'
alertIds = require '../../../common/utils/enums/util.enums.alertIds.coffee'
httpStatus = require '../../../common/utils/httpStatus.coffee'
fonts = require("../../../common/documentTemplates/signature-fonts/index.coffee")


setWatch = null
clearWatch = null
renderPromise = null
snailData = {}
rendered = false
form = null

module.exports = app.controller 'SnailCtrl'.ourNs(), [
  '$scope', '$rootScope', '$location', '$http', '$sce', '$timeout', 'RenderPdfBlob'.ourNs(), 'documentTemplates'.ourNs(), 'MainOptions'.ourNs(),
  ($scope, $rootScope, $location, $http, $sce, $timeout, RenderPdfBlob, documentTemplates, MainOptions) ->
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
        template: null
    form = $scope.form

    updateBlob = (newValue, oldValue) ->
      if rendered
        $scope.pdfPreviewBlob = $sce.trustAsResourceUrl("about:blank")
        rendered = false
      if !$scope.form?.style?.template
        $scope.formReady = false
        return
      for prop of $scope.form
        formReady = true
        snailData[prop] = _.clone($scope.form[prop])
        _.extend snailData[prop], $scope.placeholderValues[prop], (formValue, placeholderValue) ->
          # if any fields aren't filled in, we're not ready
          formReady &= !!formValue
          return formValue || "{{#{placeholderValue}}}"
        $scope.formReady = formReady
        
      doRender = () ->
        renderPromise = null
        RenderPdfBlob.toBlobUrl($scope.form.style.template, snailData)
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
    
    if !snailData.to
      # we got here through direct navigation, so we don't have data on a particular property, go to the map
      $location.url frontendRoutes.map
]
app.run ["$rootScope", '$location', '$timeout', 'events'.ourNs(), ($rootScope, $location, $timeout, Events) ->
  initiateSend = (property) ->
    ownerStreetAddress = "#{(property.owner_street_address_num||'')} #{(property.owner_street_address_name||'')} #{(property.owner_street_address_unit||'')}".trim()
    snailData.to =
      name: property.owner_name
      address_line1: property.owner_name2 || ownerStreetAddress
      address_line2: if !property.owner_name2 then null else ownerStreetAddress
      address_city: "#{property.owner_city}"
      address_state: "#{property.owner_state}"
      address_zip: "#{property.owner_zip}"
    snailData.ref =
      address_line1: "#{(property.street_address_num||'')} #{(property.street_address_name||'')} #{(property.street_address_unit||'')}".trim()
      address_city: "#{property.city}"
      address_state: "#{property.state}"
      address_zip: "#{property.zip}"
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
