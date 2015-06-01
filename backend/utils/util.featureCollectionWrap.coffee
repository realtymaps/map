_parcelPropertiesMove = [
  'rm_property_id'
  'street_address_num'
  'geom_point_json'
  'passedFilters'
]

_parcelFeature = (row, toMove = _parcelPropertiesMove, deletes = []) ->
  deletes.forEach (prop) ->
    delete row[prop]

  row.properties = {}
  toMove.forEach (prop) ->
    row.properties[prop] = row[prop]
    delete row[prop]
  row

module.exports =
  parcelFeature: _parcelFeature

  parcelFeatureCollection: (rows) ->
    rows = _.uniq rows, (r) ->
      r.rm_property_id
    rows.forEach (row) ->
      row = _parcelFeature(row)
    type: 'FeatureCollection', features: rows
