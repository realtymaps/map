keystore = require '../services/service.keystore'

getMailPrices = () ->
  keystore.getValue('mail', namespace: "pricings")

module.exports =
  getMailPrices: getMailPrices
