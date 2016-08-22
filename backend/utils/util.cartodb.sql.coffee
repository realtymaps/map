_destTable = 'parcels'

_plusSign='%2B'

_sql =
    update: """UPDATE #{_destTable}
        set street_address_num=subq.street_address_num,
        the_geom=subq.the_geom,
        num_updates=#{_destTable}.num_updates #{_plusSign} 1,
        is_active=1
        FROM (SELECT * FROM $frmTable) subq
        where #{_destTable}.rm_property_id = subq.rm_property_id;"""

    insert:"""
        INSERT INTO #{_destTable} (rm_property_id, the_geom, created_at, updated_at, is_active, num_updates, fips_code, street_address_num)
        SELECT rm_property_id, the_geom, created_at, updated_at, (not is_active::boolean)::int, 1, fips_code, street_address_num
        FROM $frmTable
        WHERE NOT EXISTS (
                SELECT * FROM #{_destTable}
                WHERE
                rm_property_id = $frmTable.rm_property_id
            );
        """
    'delete':"""
        DELETE FROM #{_destTable}
        where rm_property_id in (
        select #{_destTable}.rm_property_id
        from #{_destTable}
        LEFT JOIN $frmTable on #{_destTable}.rm_property_id = $frmTable.rm_property_id
        where $frmTable.rm_property_id isnull and #{_destTable}.fips_code = '$fipsCode'
        );
        """

    drop:'DROP TABLE $frmTable;'

_format = (sql, fipsCode) ->
  sql
  .replace('$frmTable', 'table_' + String(fipsCode))
  .replace('$fipsCode', String(fipsCode))

obj = {}
['update', 'insert', 'delete', 'drop'].forEach  (method) ->
  obj[method] = (fipsCode) ->
    _format(_sql[method], fipsCode)

module.exports = obj
