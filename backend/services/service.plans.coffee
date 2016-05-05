keystore = require '../services/service.keystore'
groupTable =  require('../config/tables').auth.group
clone = require 'clone'
numeral = require 'numeral'
logger = require '../config/logger'
{expectSingleRow} = require '../utils/util.sql.helpers'

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

getPlanId = (planName, trx) ->
  planName = planName.toLowerCase()
  getAll().then (plans) ->
    planObj = plans[planName]

    q = groupTable(transaction: trx)
    .where 'name', 'ilike', "%#{planName}%"
    .orWhere 'name', 'ilike', "%#{planObj.alias.toLowerCase()}%"


    logger.debug q.toString()

    q.then (results) ->
      expectSingleRow(results)
    .then (result) ->
      result.id

module.exports =
  getAll: getAll
  getPlanId: getPlanId
