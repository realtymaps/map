Promise = require 'bluebird'
{basePath} = require '../../globalSetup'
require("chai").should()
{expect} = require("chai")

{validators, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject} = require('../../../specUtils/promiseUtils')


describe 'Backend utils/validation.validators.geojson()', () ->
  param = 'fake'

  describe 'IS geojson', ->

    it 'point', ->
      testGeoJSon = {"type":"Point","coordinates":[-81.80912375450134,26.12772853930134],"crs":{"type":"name","properties":{"name":"EPSG:26910"}}}
      (validators.geojson()(param, testGeoJSon)).then (value) ->
        value.should.equal(testGeoJSon)

  describe 'is NOT geojson', ->

    it 'empty', () ->
      (validators.geojson()(param, '')).then (value) ->
        expect(value).not.be.ok

    it 'null', () ->
      (validators.geojson()(param, null)).then (value) ->
        expect(value).not.be.ok

    describe 'reject', ->
      it 'invalid geojson', ->
        testGeoJSon = {"type":"Point"}
        expectReject(validators.geojson()(param, testGeoJSon))
