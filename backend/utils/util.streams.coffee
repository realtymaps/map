_ = require 'lodash'
through = require 'through2'
logger = require('../config/logger').spawn("utils:streams")
{toGeoFeature} = require '../../common/utils/util.geomToGeoJson'
{Readable} = require 'stream'
split = require 'split'
require '../../common/extensions/strings'
require '../extensions/stream'



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

  write = (row, enc, cb) ->
    if !prefixWritten
      @push(new Buffer('{"type": "FeatureCollection", "features": ['))
      prefixWritten = true

    if rm_property_ids[row.rm_property_id] #GTFO
      return cb()

    rm_property_ids[row.rm_property_id] = true
    #transform
    row = toGeoFeature row,
      toMove: toMove
      deletes: deletes

    #hold off on adding to buffer so we know it has a next item to add ','
    if lastBuffStr
      @push(new Buffer lastBuffStr + ',')

    lastBuffStr = JSON.stringify(row)
    cb()

  end = (cb) ->
    if lastBuffStr
      @push(new Buffer lastBuffStr)
    @push(new Buffer(']}'))
    cb()

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
  outputStream = through.obj lineHandler, (callback) ->
    this.push(type: 'done', payload: count)
    callback()
  inputStream.pipe(splitStream).pipe(outputStream)


lineStream = ({delimitter = '\n'} = {}) ->
  lsLogger = logger.spawn("lineStream")
  ctrLogger = lsLogger.spawn("ctr")
  currentLastLine = ''

  doLines = ({chunk, line = '', where} = {}) ->
    lines = [chunk,line].join('').split(delimitter)
    lsLogger.debug -> "#{where}: lines"
    lsLogger.debug -> lines
    for l, i in lines
      if i == lines.length - 1 && where != "flush"
        line = l
        continue

      ctrLogger.debug -> i
      @emit 'line', l
      lsLogger.debug -> "#{where}: emitted line"

    lsLogger.debug -> "#{where}: exited for"
    lines = null

    return line


  transform = (chunk, enc, cb) ->
    lsLogger.debug -> '@@@@ tform @@@@'
    try
      @push(chunk)
      currentLastLine = doLines.call(@, {chunk, line:currentLastLine, where: 'tform'})
      lsLogger.debug -> 'currentLastLine'
      lsLogger.debug -> currentLastLine
      cb()
    catch error
      cb(error)

    return

  flush = (cb) ->
    lsLogger.debug -> "@@@@ flush @@@@"
    if currentLastLine?
      doLines.call(@, {chunk: currentLastLine, where: 'flush'})
    cb()

  through.obj(transform, flush)



module.exports = {
  pgStreamEscape
  geoJsonFormatter
  StringStream
  stringStream: (s) -> new StringStream(s)
  delimitedTextToObjectStream
  lineStream
}
