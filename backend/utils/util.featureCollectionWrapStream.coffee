through = require 'through'
logger = require '../config/logger'
{parcelFeature} = require './util.featureCollectionWrap'

_basicWrapStream = ->
  prefixWritten = false
  rm_property_ids = {}
  lastBuffStr = null

  write = (row) ->
    if !prefixWritten
      @queue new Buffer('{"type": "FeatureCollection", "features": [')
      prefixWritten = true

    return if rm_property_ids[row.rm_property_id] #GTFO
    rm_property_ids[row.rm_property_id] = true
    row = parcelFeature row

    #hold off on adding to buffer so we know it has a next item to add ','
    if lastBuffStr
      @queue new Buffer lastBuffStr + ','

    lastBuffStr = JSON.stringify(row)

  end = ->
    if lastBuffStr
      @queue new Buffer lastBuffStr
    @queue new Buffer(']}')
    @queue null#tell through we're done

  through(write, end)

module.exports = _basicWrapStream
