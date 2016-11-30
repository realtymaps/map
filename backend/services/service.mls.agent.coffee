tables = require '../config/tables'
logger = require('../config/logger').spawn('services:mls:agent')
_ = require 'lodash'
clone = require 'clone'

getBy = (entity, cols = '*') ->
  logger.debug -> entity
  entity = clone(entity)

  #NOTE We might want to consider saving off data_source_id and removing
  # it from the entity to use ilike instead to not worry about caps

  #DUE to 'swflmls' and 'SWFLMLS' being inconcistent
  if entity.data_source_id?
    {data_source_id} = entity
    delete entity.data_source_id

  q = tables.finalized.agent()
  .select(cols)
  .where _.extend {}, entity,
    agent_status: 'active'

  if data_source_id?
    q.where("data_source_id", 'ilike', data_source_id)

  logger.debug -> q.toString()
  q

exists = (entity, cols) ->
  getBy(entity, cols)
  .then (results) ->
    !!results.length

module.exports = {
  getBy
  exists
}
