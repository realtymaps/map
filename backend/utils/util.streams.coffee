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


pgStreamEscape = (str) ->
  str
  .replace(/\\/g, '\\\\')
  .replace(/\n/g, '\\n')
  .replace(/\r/g, '\\r')


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
  pgStreamEscape: pgStreamEscape
  geoJsonFormatter: geoJsonFormatter
  StringStream: StringStream
