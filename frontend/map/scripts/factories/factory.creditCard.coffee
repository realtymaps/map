app = require '../app.coffee'
_ = require 'lodash'

app.factory 'rmapsCreditCardFactory', (
$uibModal
rmapsCreditCardModalFactory
rmapsCreditCardService
rmapsPaymentMethodService) ->
  ($scope) ->
    $scope.processing = 0

    $scope.data = _.merge($scope.data || {}, payment: null)

    process = (promise) ->
      $scope.processing++
      promise.finally () ->
        $scope.processing--

    getAllPayments = () ->
      process rmapsPaymentMethodService.getAll(cache:false)
      .then (sources) ->
        $scope.data.payments = sources

    hasCards = () ->
      !!$scope.data?.payments?.length

    $scope.replaceCC = () ->
      rmapsCreditCardModalFactory({
        title: "Replace Credit Card"
        modalActionMsg: "New default credit card successfully set."
        modalAction: rmapsCreditCardService.replace
      })
      .result.then (result) ->
        if !result
          throw new Error('No CreditCard Replaced')

        return $scope.data.payment = result

    addCC = $scope.addCC = () ->
      rmapsCreditCardModalFactory({
        title:"Add Credit Card"
        modalActionMsg: "New credit card added."
        modalAction: rmapsCreditCardService.add
      })
      .result.then (result) ->
        if !result
          throw new Error('No CreditCard Added')

        return $scope.data.payments.push(result)

    defaultCC = $scope.defaultCC = (source) ->
      rmapsPaymentMethodService.setDefault(source.id, cache:false)
      .then () ->
        getAllPayments()

    removeCC = $scope.removeCC = (source) ->
      rmapsPaymentMethodService.remove(source.id)
      .then () ->
        getAllPayments()

    getAllPayments()

    return {
      getAllPayments
      hasCards
      process
      addCC
      defaultCC
      removeCC
    }
