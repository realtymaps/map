{lookup, config} = require '../config/tables'
{basicColumns} = require '../utils/util.sql.columns'
clone =  require 'clone'
logger = require('../config/logger').spawn('services:mls')
_ = require 'lodash'

supported =
  getAll: () ->
    config.mls().select('id').where('id', '!=', 'temp')

  getAllStates: () ->
    config.mls()
    .distinct('state')
    .join lookup.mls.tableName, () ->
      @on lookup.mls.tableName + '.mls', 'ilike', config.mls.tableName + ".id"
    .where(config.mls.tableName + ".id", '!=', 'temp')

  getPossibleStates: () ->
    lookup.mls()
    .distinct('state')
    .orderBy('state')

toFipsCounties =
  getAllMlsCodes: (queryObj) ->
    queryObj = _.mapKeys clone(queryObj), (val, key) ->
      return key if key == 'state'
      lookup.mls_m2m_fips_code_county.tableName + '.' + key

    query = lookup.mls_m2m_fips_code_county()
    .distinct('mls', 'state', "#{lookup.fipsCodes.tableName}.county", "fips_code")
    .join lookup.fipsCodes.tableName, lookup.fipsCodes.tableName + '.code',
      lookup.mls_m2m_fips_code_county.tableName + '.fips_code'

    if queryObj.mls?
      query.where 'mls', "ilike", queryObj.mls
      delete queryObj.mls

    if Object.keys(queryObj).length
      query.where queryObj


    logger.debug query.toString()

    query

  getAllSupportedMlsCodes: (queryObj) ->
    q = @getAllMlsCodes(queryObj)
    .join config.mls.tableName,
      lookup.mls_m2m_fips_code_county.tableName + '.mls', config.mls.tableName + '.id'
    logger.debug q.toString()
    q


getAll = (queryObj) ->
  query = lookup.mls().select(basicColumns.mls)
  if queryObj?
    query.where queryObj
  query

getAllSupported = (queryObj) ->
  query = lookup.mls().select(basicColumns.mls.map (name) -> lookup.mls.tableName + '.' + name)
  .join config.mls.tableName, lookup.mls.tableName + '.mls', config.mls.tableName + '.id'

  if queryObj?
    query.where queryObj
  query

module.exports = {
  getAll
  getAllSupported
  toFipsCounties
  supported
}
