{lookup} = require '../config/tables'
{Crud} = require '../utils/crud/util.crud.service.helpers'
# logger = require '../config/logger'

class FipsCodeService extends Crud
  constructor: (dbFn = lookup.fipsCodes) ->
    # logger.debug.cyan dbFn, true
    super(dbFn, 'code')

  mainQuery: (stateName) ->
    @dbFn().where(state: stateName)

  getAllByState: (stateName) ->
    @mainQuery(stateName)

  getAllByStateCounty: (stateName, countyName) ->
    @mainQuery(stateName).where(county: countyName)

  getAllByStateLikeCounty: (countyName) ->
    @mainQuery(stateName)
    .where(stateName,'county','like', "%#{countyName}%")

module.exports = new FipsCodeService()
