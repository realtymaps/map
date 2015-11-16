_ = require 'lodash'
through = require 'through'
through2 = require 'through2'
logger = require '../config/logger'
{parcelFeature} = require './util.geomToGeoJson'
{Readable} = require 'stream'
split = require 'split'


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


delimitedTextToObjectStream = (inputStream, delimiter, columnsHandler) ->
  columnNum = 0
  count = 0
  outputStream = through2.obj()
  splitStream = split()
  finish = (err) ->
    if err
      outputStream.write(type: 'error', payload: err)
    else
      outputStream.write(type: 'done', payload: count)
    outputStream.end()
    splitStream.removeAllListeners()
  inputStream.on('error', finish)
  splitStream.on('error', finish)
  splitStream.on('end', finish)
  outputStream.write(type: 'delimiter', payload: delimiter)
  
  lineHandler = (line) ->
    count++
    colCount = line.split(delimiter).length
    if colCount != columnNum
      console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ line #{count} has only #{colCount} columns, expecting #{columnNum}:\n=================: #{JSON.stringify(line)}")
    outputStream.write(type: 'data', payload: line)
  if !columnsHandler
    columnsHandler = (headers) -> headers.split(delimiter)  # generic handler
  if _.isArray(columnsHandler)
    columnNum = columnsHandler.length
    console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Expecting #{columnNum} columns")
    outputStream.write(type: 'columns', payload: columnsHandler)
    splitStream.on('data', lineHandler)
  else
    splitStream.once 'data', (headerLine) ->
      columns = columnsHandler(headerLine).split(delimiter)
      columnNum = columns.length
      console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Expecting #{columnNum} columns")
      outputStream.write(type: 'columns', payload: columns)
      splitStream.on('data', lineHandler)
  inputStream.pipe(splitStream)
  outputStream


module.exports =
  pgStreamEscape: pgStreamEscape
  geoJsonFormatter: geoJsonFormatter
  StringStream: StringStream
  delimitedTextToObjectStream: delimitedTextToObjectStream
