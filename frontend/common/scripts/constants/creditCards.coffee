_ = require 'lodash'

keysToValues = require '../../../../common/utils/util.keysToValues.coffee'
mod = require '../module.coffee'

mod.constant 'rmapsCreditCardConstants', keysToValues
  visa: undefined
  mastercard: undefined
  discover: undefined
  amex: undefined
  americanexpress: 'amex'
  'american express': 'amex'
  'google-wallet': undefined
  paypal: undefined
  'apple-pay': undefined

mod.service 'rmapsFaCreditCardsService', (rmapsCreditCardConstants) ->
  creditCards = rmapsCreditCardConstants
  faCards = {}

  _faValidCard = (typeStr) ->
    "fa-cc-#{typeStr}"

  for card, cardValue of creditCards
    faCards[card] = _faValidCard(cardValue)

  faCards

  getCard: (typeStr) ->
    card = faCards[typeStr] or 'fa-credit-card'

  cards: faCards
