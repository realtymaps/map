Promise = require 'bluebird'
keystore = require '../services/service.keystore'

getMailPrices = () ->
  keystore.getValue('mail', namespace: "pricings")

getPriceForLetter = (letter) -> Promise.try () ->
  keystore.cache.getValue('mail', namespace: "pricings")
  .then (pricings) ->
    console.log "pricings: #{JSON.stringify(pricings)}"
    ###
      price calculation
    ###


module.exports =
  getMailPrices: getMailPrices
  getPriceForLetter: getPriceForLetter
