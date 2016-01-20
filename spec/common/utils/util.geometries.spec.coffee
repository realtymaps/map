hack = require '../../../common/utils/webpackHack.coffee'
{expect,should} =require("chai")
should()

describe "util.geometries", ->
  before ->
    @subject = require "../../../common/utils/util.geometries.coffee"

  it 'exists', ->
    @subject.should.equal.ok

  describe 'Point', ->
    it 'exists', ->
      @subject.Point.should.equal.ok

    describe 'creation', ->
      it 'x y', ->
        testCoords = [45, 100]
        p = new @subject.Point(testCoords[0], testCoords[1])
        expect(p.lat).to.equal testCoords[0]
        expect(p.lon).to.equal testCoords[1]

      it 'object, latitude: longitude', ->
        testCoords = [45, 100]
        p = new @subject.Point( latitude: testCoords[0], longitude: testCoords[1])
        expect(p.lat).to.equal testCoords[0]
        expect(p.lon).to.equal testCoords[1]

      it 'object, lat: lon', ->
        testCoords = [45, 100]
        p = new @subject.Point( lat: testCoords[0], lon: testCoords[1])
        expect(p.lat).to.equal testCoords[0]
        expect(p.lon).to.equal testCoords[1]

    describe 'sets', ->
      it 'lat', ->
        testCoords = [45, 100]
        p = new @subject.Point( latitude: testCoords[0], longitude: testCoords[1])
        p.setLat 20
        expect(p.lat).to.equal 20
        expect(p.latitude).to.equal 20
        expect(p.lon).to.equal 100
        expect(p.longitude).to.equal 100

      it 'lon', ->
        testCoords = [45, 100]
        p = new @subject.Point( latitude: testCoords[0], longitude: testCoords[1])
        p.setLon 20
        expect(p.lat).to.equal  45
        expect(p.latitude).to.equal 45
        expect(p.lon).to.equal 20
        expect(p.longitude).to.equal 20
