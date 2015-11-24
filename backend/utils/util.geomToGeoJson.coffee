_ = require 'lodash'

toGeoFeature = (row, opts) ->
  opts.deletes?.forEach (prop) ->
    delete row[prop]

  row.properties = {}

  if opts?.geometry?
    geometryStr = _.find opts.geometry, (geomName) ->
      row[geomName]?
    row.geometry = row[geometryStr]

    # console.log row, true

  opts?.toMove?.forEach (prop) ->
    row.properties[prop] = row[prop]
    delete row[prop]

  row.type = 'Feature'


  row

module.exports =
  toGeoFeature: toGeoFeature
  toGeoFeatureCollection: (opts) ->
    (rows) ->
      if opts?.uniqueKey?
        rows = _.uniq rows, (r) ->
          r[opts.uniqueKey]

      toGeoFeature(row, opts) for row in rows
      type: 'FeatureCollection', features: rows
