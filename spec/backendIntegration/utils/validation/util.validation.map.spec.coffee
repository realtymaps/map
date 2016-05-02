Promise = require 'bluebird'
{basePath} = require '../../globalSetup'

{validators, DataValidationError, validateAndTransform} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.map()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should resolve or reject based on toString() equality to any value found in the map', () ->
    [
      expectResolve(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, '5')).then (value) ->
        value.should.equal(10)
      expectReject(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, 'xxx'), DataValidationError)
      expectResolve(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, 10)).then (value) ->
        value.should.equal(999)
      expectResolve(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1})(param, 'x')).then (value) ->
        value.should.equal(1)
    ]

  promiseIt 'should pass through any value not found in the map when passUnmapped is true', () ->
    [
      expectResolve(validators.map(map: {abc: 'xyz', '5': 10, '10': 999, x: 1}, passUnmapped: true)(param, 'xxx')).then (value) ->
        value.should.equal('xxx')
    ]

  promiseIt 'should map values', () ->
    transformMap =
      map:
        dog: 'bark'
        cat: 'meow'
        bigCat: 'RAAAR'
    orig =
      a:'dog'
      b:'cat'
      c:'bigCat'
    [
      expectResolve validateAndTransform orig,
        a: validators.map (transformMap)
        b: validators.map (transformMap)
        c: validators.map (transformMap)
      .then (value) ->
        value.should.eql({a: 'bark', b: 'meow', c: 'RAAAR'})
    ]

  promiseIt 'should map lookup values', () ->
    transformMap =
      lookup:
        dataSourceId: 'blackknight'
        dataListType: 'deed'
        lookupName: 'ADJUSTABLE_RATE_INDEX'
    orig =
      a:'12MTA'
      b:'COFI'
      c:'PRIME'
    [
      expectResolve validateAndTransform orig,
        a: validators.map (transformMap)
        b: validators.map (transformMap)
        c: validators.map (transformMap)
      .then (value) ->
        value.should.eql({a: 'Twelve Month Average', b: 'Cost of Funds', c: 'Prime'})
    ]

  promiseIt 'generalize values', () ->
    notForSale = 'not-for-sale'
    transformMap =
      map:
        'off-market': notForSale
        sold: notForSale
        pending: notForSale
    orig =
      a:'pending'
      b:'sold'
      c:'off-market'
    [
      expectResolve validateAndTransform orig,
        a: validators.map (transformMap)
        b: validators.map (transformMap)
        c: validators.map (transformMap)
      .then (value) ->
        value.should.eql({a: notForSale, b: notForSale, c: notForSale})
    ]
