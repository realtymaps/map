Promise = require 'bluebird'
keystore = require '../services/service.keystore'
config = require('../config/config')


getMailPrices = () ->
  keystore.getValue('mail', namespace: "pricings")

getPricePerLetter = ({pages, color}) -> Promise.try () ->
  keystore.cache.getValue('mail', namespace: "pricings")
  .then (pricings) ->
    if color
      price = config.MAILING_PLATFORM.GET_PRICE(
        firstPage: pricings.colorPage
        extraPage: pricings.colorExtra
        pages: pages
      )
    else
      price = config.MAILING_PLATFORM.GET_PRICE(
        firstPage: pricings.bnwPage
        extraPage: pricings.bnwExtra
        pages: pages
      )

    return price


module.exports =
  getMailPrices: getMailPrices
  getPricePerLetter: getPricePerLetter
