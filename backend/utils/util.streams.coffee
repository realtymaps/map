_ = require 'lodash'
through = require 'through'
through2 = require 'through2'
logger = require '../config/logger'
{toGeoFeature} = require '../../common/utils/util.geomToGeoJson'
{Readable} = require 'stream'
split = require 'split'


class StringStream extends Readable
  constructor: (@str) ->
    super()

  _read: (size) ->
    @push @str
    @push null


_escapeCache = {}
pgStreamEscape = (str, extraEscape) ->
  escaped = str
  .replace(/\\/g, '\\\\')
  .replace(/\n/g, '\\n')
  .replace(/\r/g, '\\r')
  if !extraEscape
    return escaped
  else
    # pgStreamEscape could run many times -- potentially once for each value in each row in a data file.  So we want to
    # be very efficient, caching the regex and replacement string rather than rebuilding them both each time
    if !_escapeCache[extraEscape]
      _escapeCache[extraEscape] = {re: new RegExp(extraEscape, 'g'), replacement: "\\#{extraEscape}"}
    return escaped.replace(_escapeCache[extraEscape].re, _escapeCache[extraEscape].replacement)


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
    row = toGeoFeature row,
      toMove: toMove
      deletes: deletes

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


delimitedTextToObjectStream = (inputStream, delimiter, columnsHandler) ->
  count = 0
  splitStream = split()
  doPreamble = true

  if !columnsHandler
    columnsHandler = (headers) -> headers.split(delimiter)  # generic handler

  onError = (err) ->
    outputStream.write(type: 'error', payload: err)
  lineHandler = (line, encoding, callback) ->
    if !line
      # hide empty lines
      return callback()
    if doPreamble
      doPreamble = false
      this.push(type: 'delimiter', payload: delimiter)
      if !_.isArray(columnsHandler)
        columns = columnsHandler(line)
        this.push(type: 'columns', payload: columns)
        return callback()
      this.push(type: 'columns', payload: columnsHandler)
    count++
    this.push(type: 'data', payload: line)
    callback()

  inputStream.on('error', onError)
  splitStream.on('error', onError)
  outputStream = through2.obj lineHandler, (callback) ->
    this.push(type: 'done', payload: count)
    callback()
  inputStream.pipe(splitStream).pipe(outputStream)


module.exports = {
  pgStreamEscape
  geoJsonFormatter
  StringStream
  delimitedTextToObjectStream
}
