keystore = require '../services/service.keystore'
clone = require 'clone'
numeral = require 'numeral'

getAll = () ->
  keystore.cache.getValuesMap('plans')
  .then (plans) ->
    for key, val of plans
      val.priceFormatted = '$' + numeral(val.price).format('0.00a')
      copy = clone val
      if copy.alias?
        copy.alias = key
        plans[val.alias] = copy
    plans

module.exports =
  getAll: getAll
