toGeoFeature = (row, toMove, deletes = []) ->
  deletes.forEach (prop) ->
    delete row[prop]

  row.properties = {}
  toMove.forEach (prop) ->
    row.properties[prop] = row[prop]
    delete row[prop]
  row

module.exports =
  toGeoFeature: toGeoFeature
  toGeoFeatureCollection: (toMove, uniqueKey, deletes) ->
    (rows) ->
      if uniqueKey
        rows = _.uniq rows, (r) ->
          r[uniqueKey]

      rows.forEach (row) ->
        row = toGeoFeature(row, toMove, deletes)
      type: 'FeatureCollection', features: rows
