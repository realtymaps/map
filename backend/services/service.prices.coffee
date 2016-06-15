keystore = require '../services/service.keystore'

getMailPrices = () ->
  console.log "getMailPrices()"
  keystore.getValue('mail', namespace: "pricings")

module.exports =
  getMailPrices: getMailPrices
