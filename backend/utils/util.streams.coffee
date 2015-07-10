_ = require 'lodash'
through = require 'through'
logger = require '../config/logger'
{parcelFeature} = require './util.featureCollectionWrap'
{Readable} = require 'stream'

class StringStream extends Readable
  constructor: (@str) ->
    super()

  _read: (size) ->
    @push @str
    @push null

_escape = (str, delimiter) ->
  return str
  .replace(/\\/g, '\\\\')
  .replace(/\n/g, '\\n')
  .replace(/\r/g, '\\r')
  .replace(new RegExp(delimiter, 'g'), '\\'+delimiter)

objectsToPgText = (textFields, jsonFields, _options={}) ->
  defaults =
    null: '\\N'
    delimiter: '\t'
    encoding: 'utf-8'
  options = _.extend({}, defaults, _options)
  write = (obj) ->
    textParts = _.map textFields, (longName, systemKey) ->
      val = obj[systemKey]
      if !val?
        return options.null
      else
        return _escape(''+val, options.delimiter)
    jsonParts = _.map jsonFields, (longName, systemKey) ->
      val = obj[systemKey]
      if !val?
        return options.null
      else
        return _escape(JSON.stringify(val), options.delimiter)

    @queue new Buffer(textParts.concat(jsonParts).join(options.delimiter)+'\n', options.encoding)
  end = () ->
    @queue new Buffer('\\.\n', options.encoding)
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
  StringStream: StringStream
