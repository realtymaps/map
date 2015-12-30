{lookup} = require '../config/tables'
{Crud} = require '../utils/crud/util.crud.service.helpers'
# logger = require '../config/logger'

class FipsCodeService extends Crud
  constructor: (dbFn = lookup.fipsCodes) ->
    # logger.debug.cyan dbFn, true
    super(dbFn, 'code')

  getAllByState: (stateName) ->
    @dbFn().where(state: stateName).then (results) ->
      obj = {}
      obj[stateName] = results.map (r) ->
        delete r.state
        r

module.exports = new FipsCodeService()
