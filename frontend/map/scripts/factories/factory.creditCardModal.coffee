app = require '../app.coffee'
creditCardTemplate = require('../../html/views/templates/modals/creditCard.jade')()

app.factory 'rmapsCreditCardModalFactory', ($uibModal) ->
  ({title, modalAction, modalActionMsg} = {}) ->
    $uibModal.open
      animation: true
      template: creditCardTemplate
      controller: 'rmapsCreditCardModalCtrl'
      resolve: {
        # everything has to be wrapped in callbacks otherwise the injector
        # tries to use strings to find and inject a provider
        modalTitle: () -> title
        showCancelButton: () -> false
        modalAction: () -> modalAction
        modalActionMsg : () -> modalActionMsg
      }
