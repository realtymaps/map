Promise = require 'bluebird'
keystore = require '../services/service.keystore'
config = require('../config/config')


getMailPrices = () ->
  keystore.getValue('mail', namespace: "pricings")

getPriceForLetter = ({pages, recipientCount, color}) -> Promise.try () ->
  keystore.cache.getValue('mail', namespace: "pricings")
  .then (pricings) ->
    if color
      price = config.MAILING_PLATFORM.GET_PRICE(
        firstPage: pricings.colorPage
        extraPage: pricings.colorExtra
        pages: pages
        recipientCount: recipientCount
      )
    else
      price = config.MAILING_PLATFORM.GET_PRICE(
        firstPage: pricings.bnwPage
        extraPage: pricings.bnwExtra
        pages: pages
        recipientCount: recipientCount
      )

    return price


module.exports =
  getMailPrices: getMailPrices
  getPriceForLetter: getPriceForLetter
