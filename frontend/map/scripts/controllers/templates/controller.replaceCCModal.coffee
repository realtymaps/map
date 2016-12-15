app = require '../../app.coffee'


app.controller 'rmapsReplaceCCModalCtrl',
  ($scope, $sce, modalTitle, showCancelButton, rmapsCreditCardService) ->
    # $scope.modalBody = modalBody
    $scope.card = rmapsCreditCardService.newCard()
    $scope.modalTitle = modalTitle
    $scope.showCancelButton = showCancelButton
    $scope.successButton = false
    $scope.showErrOkButton = false
    $scope.message = null

    # set some view helpers for classes and cards (somewhat based on what's in onboarding)
    $scope.view =
      submittalClass: rmapsCreditCardService.submittalClass
      doShowRequired: rmapsCreditCardService.doShowRequired

    $scope.exitCC = (result) ->
      $scope.$close(result)

    $scope.submitCC = () ->
      rmapsCreditCardService.replace $scope.card
      .then (savedCard) ->

        # expose success "ok" button
        $scope.successButton = true
        $scope.hasError = false
        $scope.message = "New default credit card successfully set."

        # set $scope.card to the new card; it gets passed back through modal close to keep parent update
        $scope.card = savedCard

      .catch (err) ->
        $scope.hasError = true
        if _.isEmpty err
          $scope.message = "There was a problem processing this form."
        else
          $scope.message = $sce.trustAsHtml(err.data.alert.msg)

        # reinit card & form
        $scope.card = rmapsCreditCardService.newCard()
        $scope.ccForm.$setPristine()
        $scope.ccForm.$setValidity()
        $scope.ccForm.$setUntouched()
