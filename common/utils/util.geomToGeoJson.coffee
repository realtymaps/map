_ = require 'lodash'
#note we could use _.clone, but it is known to be slow in 3.X, 4.X is very fast
clone = require 'clone'

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

toGeoFeatureCollection = ({rows = [], opts = {}, doClone = true}) ->
  rows = clone rows if doClone
  if opts?.uniqueKey?
    rows = _.uniq rows, (r) ->
      r[opts.uniqueKey]

  # coffeelint: disable=check_scope
  rows = for key, row of rows
  # coffeelint: enable=check_scope
    toGeoFeature(row, opts)

  type: 'FeatureCollection'
  features: rows

module.exports = {
  toGeoFeature
  toGeoFeatureCollection
}
