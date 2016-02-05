_ =  require 'lodash'
{lookup} = require '../config/tables'
{Crud} = require '../utils/crud/util.crud.service.helpers'
mlsService = require './service.mls'

class FipsCodeService extends Crud
  constructor: (dbFn = lookup.fipsCodes) ->
    # logger.debug.cyan dbFn, true
    super(dbFn, 'code')

  getAll: (queryObj) ->
    @dbFn().where(queryObj)

module.exports = _.extend new FipsCodeService(), mlsService.toFipsCounties
