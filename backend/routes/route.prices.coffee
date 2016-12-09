priceSvc = require '../services/service.prices'
auth = require '../utils/util.auth'

module.exports =
  mail:
    method: "get"
    handleQuery: true
    handle: (req, res, next) ->
      priceSvc.getMailPrices()
