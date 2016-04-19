###global _:true###
app = require '../app.coffee'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
apiBase = backendRoutes.paymentMethod


# This service centralizes credit-card operators, leveraging the angular-stripe (stripe.js) service that
#   translates sensitive data into tokens and performs the operations, coordinating w/ paymentmethod service and
#   backend as needed.
app.service 'rmapsCreditCardService', ($log, $q, $http, stripe, rmapsCreditCardConstants, rmapsFaCreditCardsService, rmapsPaymentMethodService) ->
  $log = $log.spawn("payment:rmapsCreditCardFactory")

  service =
    submittalClass: ''

    # send default card values (empty)
    newCard: () ->
      card =
        name: null
        exp_month: null
        exp_year: null
        address_zip: null
        cvc: null

    # replace the default pay source with given card
    # Note: this simply performs an update on customer source, which
    #   replaces the current active source.
    # If appending sources is desired, a new operator (and flow through backend)
    #   may be required.
    replace: (card) ->
      stripe.card.createToken card
      .then (token) ->
        rmapsPaymentMethodService.replace token.id

    # css class helper
    getCardClass: (typeStr) ->
      if !typeStr then return ''
      'fa fa-2x ' +  rmapsFaCreditCardsService.getCard(typeStr.toLowerCase())

    # validation helper 
    doShowRequired: (formField, rootForm) ->  # based on `behaveLikeAngularValidation` from onboarding
      fieldIsRequired = formField.$touched && formField.$invalid && !formField.$viewValue
      attemptedSubmital = !rootForm.$pending && !formField.$touched
      @submittalClass = if attemptedSubmital then 'has-error' else ''
      fieldIsRequired or attemptedSubmital
