_parcelDeletes = ['geom_polys_raw', 'geom_point_raw']
_parcelPropertiesMove = [
  'rm_property_id'
  'street_address_num'
  'geom_point_json'
  'passedFilters'
]

_parcelFeature = (row) ->
  _parcelDeletes.forEach (prop) ->
    delete row[prop]

  row.properties = {}
  _parcelPropertiesMove.forEach (prop) ->
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
