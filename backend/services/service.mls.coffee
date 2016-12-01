{lookup, config, auth, finalized} = require '../config/tables'
{basicColumns} = require '../utils/util.sql.columns'
sqlHelpers = require '../utils/util.sql.helpers'
clone =  require 'clone'
logger = require('../config/logger').spawn('services:mls')
dbs = require '../config/dbs'
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

getForUser = (session) ->
  dbs.transaction (transaction) ->
    auth.user({transaction})
    .select(['first_name', 'last_name', 'mlses_verified']) # add licence_number?
    .where(id: session.userid)
    .then (results) ->
      sqlHelpers.expectSingleRow(results)
    .then (user) ->
      sqlHelpers.whereIn(config.mls({transaction}), config.mls.tableName + '.id', user.mlses_verified)
      .then (mlses) ->
        mlses


getCollectiveCenter = (mlses) ->
  #st_collect aggregates all points
  #then we get the center of those via st_centroid
  rawSelect = lookup.fipsCodes.raw('st_asgeojson(st_centroid(st_collect(??)))::json as geo_json', 'geometry_center_raw')

  questionMarks = (mlses.map () -> '?').join(',')

  whereRaw = lookup.fipsCodes.raw("?? ilike ANY(ARRAY[#{questionMarks}])", [
    lookup.mls_m2m_fips_code_county.tableName + ".mls"
  ].concat(mlses))

  logger.debugQuery(
    lookup.fipsCodes()
    .select(rawSelect)
    .join(lookup.mls_m2m_fips_code_county.tableName,
      lookup.mls_m2m_fips_code_county.tableName + '.fips_code',
      lookup.fipsCodes.tableName + '.code')
    .where(whereRaw)
  )

module.exports = {
  getAll
  getAllSupported
  getForUser
  getCollectiveCenter
  toFipsCounties
  supported
}
