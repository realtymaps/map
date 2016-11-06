tables = require '../config/tables'
logger = require('../config/logger').spawn('services:mls:agent')
_ = require 'lodash'

getBy = (entity, cols = '*') ->
  logger.debug -> entity

  #NOTE We might want to consider saving off data_source_id and removing
  # it from the entity to use ilike instead to not worry about caps

  q = tables.finalized.agent()
  .select(cols)
  .where _.extend {}, entity,
    agent_status: 'active'

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
