_ = require 'lodash'
through = require 'through'
logger = require '../config/logger'
{parcelFeature} = require './util.featureCollectionWrap'


objectsToPgText = (fields, _options={}) ->
  defaults =
    null: '\\N'
    delimiter: '\t'
    encoding: 'utf-8'
  options = _.extend({}, defaults, _options)
  write = (obj) ->
    parts = _.map fields, (field) ->
      val = obj[field]
      if !val?
        return options.null
      else
        return val.replace(/\\/g, '\\\\')
        .replace(/\n/g, '\\n')
        .replace(/\r/g, '\\r')
        .replace(new RegExp(options.delimiter, 'g'), '\\'+options.delimiter)
    @queue parts.join(options.delimiter)+'\n'
  end = () ->
    @queue new Buffer('\\.\n')
    @queue null
  through(write, end)


geoJsonFormatter = (toMove, deletes) ->
  prefixWritten = false
  rm_property_ids = {}
  lastBuffStr = null

  write = (row) ->
    if !prefixWritten
      @queue new Buffer('{"type": "FeatureCollection", "features": [')
      prefixWritten = true

    return if rm_property_ids[row.rm_property_id] #GTFO
    rm_property_ids[row.rm_property_id] = true
    row = parcelFeature row, toMove, deletes

    #hold off on adding to buffer so we know it has a next item to add ','
    if lastBuffStr
      @queue new Buffer lastBuffStr + ','

    lastBuffStr = JSON.stringify(row)

  end = () ->
    if lastBuffStr
      @queue new Buffer lastBuffStr
    @queue new Buffer(']}')
    @queue null#tell through we're done

  through(write, end)


module.exports =
  objectsToPgText: objectsToPgText
  geoJsonFormatter: geoJsonFormatter
