_ =  require 'lodash'
{lookup} = require '../config/tables'
ServiceCrud = require '../utils/crud/util.ezcrud.service.helpers'
mlsService = require './service.mls'
sqlHelpers = require '../utils/util.sql.helpers'
logger = require('../config/logger').spawn('services:fipsCodes')

class FipsCodeService extends ServiceCrud
  getAll: (queryObj) ->
    @dbFn().where(queryObj)

  getCollectiveCenter: ({fipsCodes, mlses}) ->
    if !mlses?.length
      #st_collect aggregates all points
      #then we get the center of those via st_centroid
      rawSelect = @dbFn.raw 'st_asgeojson(st_centroid(st_collect(??)))::json as geo_json', 'geometry_center_raw'

      return logger.debugQuery(
        sqlHelpers.whereAndWhereIn(@dbFn().select(rawSelect)
        , code: fipsCodes)
      )

    logger.debugQuery(
      sqlHelpers.orWhereAndWhereIn(
        mlsService.getCollectiveCenter(mlses), code: fipsCodes))


module.exports = _.extend new FipsCodeService(lookup.fipsCodes, idKey: 'code'), mlsService.toFipsCounties
