dbs = require '../config/dbs'

cartodbSqlFactory = (destTable = 'parcels') ->
  if !destTable
    throw new Error 'destTable undefined'

  #NOTE: KNEX does not handle postgress :: cast well at all so use () to cast
  _sql =
      update: """UPDATE :destTable:
          set street_address_num=subq.street_address_num,
          the_geom=subq.the_geom,
          num_updates=:destTable:."num_updates" + 1,
          is_active=1
          FROM (SELECT * FROM :frmTable:) subq
          where :destTable:."rm_property_id" = subq.rm_property_id;"""

      insert:"""
          INSERT INTO :destTable: (rm_property_id, the_geom, created_at, updated_at, is_active, num_updates, fips_code, street_address_num)
          SELECT rm_property_id, the_geom, created_at, updated_at, CAST(not CAST(is_active as boolean) as int), 1, fips_code, street_address_num
          FROM :frmTable:
          WHERE NOT EXISTS (
                  SELECT * FROM :destTable:
                  WHERE
                  rm_property_id = :frmTable:."rm_property_id"
              );
          """
      'delete':"""
          DELETE FROM :destTable:
          where rm_property_id in (
          select :destTable:."rm_property_id"
          from :destTable:
          LEFT JOIN :frmTable: on :destTable:."rm_property_id" = :frmTable:."rm_property_id"
          where :frmTable:."rm_property_id" isnull and :destTable:."fips_code" = :fipsCode
          );
          """

      drop:'DROP TABLE :frmTable:;'

      indexes: """
      CREATE INDEX idx_:frmTable:_rm_property_id ON :frmTable: USING btree (rm_property_id);
      CREATE INDEX idx_:frmTable:_fips_code_id ON :frmTable: USING btree (fips_code);
      CREATE INDEX idx_:frmTable:_the_geom_fips_code_id ON :frmTable: USING gist (the_geom);
      """
      drop_indexes: """
      DROP INDEX idx_:idx_name:_rm_property_id;
      DROP INDEX idx_:idx_name:_fips_code_id;
      DROP INDEX idx_:idx_name:_the_geom_fips_code_id;
      """

  _format = ({sql, fipsCode, tableName}) ->
    dbs.get('main').raw(sql, {
      destTable
      frmTable: tableName
      fipsCode
    }).toString()

  obj = {}

  for method in Object.keys(_sql)
    do (method) ->
      obj[method] = ({fipsCode = '', tableName, idxName} = {}) ->
        fipsCode = fipsCode.toString() + ''
        if method != 'indexes' && method != 'drop_indexes'
          return _format {sql: _sql[method], fipsCode, tableName}
        _sql[method]
        .replace(/:frmTable:/g, tableName)
        .replace(/:idx_name:/g, idxName || tableName)
  obj

module.exports = cartodbSqlFactory
