{basePath} = require '../globalSetup'
streamUtil = require("#{basePath}/utils/util.streams")
require('chai').should()
fs = require 'fs'


describe 'util.streams', ->

  describe 'lineStream', ->
    it 'finds lines', ->
      lines = """
      Line1
      Line2
      """

      splitLines = lines.split("\n")
      index = 0

      streamUtil.stringStream(lines)
      .pipe(streamUtil.lineStream())
      .on 'line', (line) ->
        splitLines[index].should.be.eql(line)
        index++
      .toPromise()
      .then () ->
        index.should.be.equal(splitLines.length)


    it 'larger: finds lines', ->
      index = 0
      fs.createReadStream('./spec/fixtures/dummy.txt')
      .pipe(streamUtil.lineStream())
      .on 'line', (line) ->
        index++
      .toPromise()
      .then () ->
        index.should.be.equal(2044)
