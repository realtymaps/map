Promise = require 'bluebird'
basePath = require '../basePath'


{validators, validateAndTransform, DataValidationError} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../specUtils/promiseUtils')


describe 'utils/validation.validateAndTransform()'.ns().ns('Backend'), ->

  promiseIt "should transform all parameters that have transforms, and omit parameters that don't", () ->
    [
      expectResolve validateAndTransform {a: 'abc', b: '5.2'},
        a: validators.string(forceUpperCase: true)
        b: validators.float()
      .then (values) ->
        values.should.eql({a: 'ABC', b: 5.2})
      expectResolve(validateAndTransform {a: 'abc', b: '5.2'}, {})
      .then (values) ->
        values.should.eql({})
    ]

  promiseIt 'should reject if any parameters fail validation', () ->
    expectReject validateAndTransform {a: 'abc', b: '5.2'},
      a: validators.string(forceUpperCase: true)
      b: validators.float(max: 5.1)
    , DataValidationError

  promiseIt 'should reject if a required parameter is undefined', () ->
    [
      expectResolve validateAndTransform {},
        a: validators.noop
        c: validators.defaults(defaultValue: 1)
        d: validators.defaults(defaultValue: null)
      .then (value) ->
        value.should.eql({a: undefined, c: 1, d: null})
      expectReject(validateAndTransform({}, {a: required: true}), DataValidationError)
    ]

  promiseIt 'mutated original val does not effect transform', () ->
    orig = {a:2}
    [
      expectResolve validateAndTransform orig,
        a: validators.noop
        c: validators.defaults(defaultValue: 1)
        d: validators.defaults(defaultValue: null)
      .then (value) ->
        value.should.eql({a: orig.a, c: 1, d: null})
        orig.a = 3
        value.a.should.not.eql orig.a
    ]

  promiseIt 'should perform iterative validation when a validator is an array', () ->
    [
      expectResolve validateAndTransform {a: null},
        a: [validators.defaults(defaultValue: '123'), validators.integer()]
      .then (value) ->
        value.should.eql({a: 123})
      expectReject validateAndTransform {a: null},
        a: [validators.defaults(defaultValue: '123'), validators.integer(max: 100)]
      , DataValidationError
      # even nested arrays
      expectResolve validateAndTransform {a: null},
        a: [
          [validators.defaults(defaultValue: 'abc123def456'), validators.string(replace: [/^[^\d]*(\d+).*$/, "$1.0$1"])]
          validators.float()
        ]
      .then (value) ->
        value.should.eql({a: 123.0123})
    ]

  promiseIt 'should use the input to get data source key', () ->
    [
      expectResolve(validateAndTransform {a: 123}, {b: input: 'a'})
      .then (value) ->
        value.should.eql({b: 123})
    ]

  promiseIt 'should build an array of source values if input is an array', () ->
    [
      expectResolve validateAndTransform {a: "1", f: "3", q: "2"},
        z:
          input: ["q", "f", "a"]
          transform: validators.array(subValidateEach: validators.integer())
      .then (value) ->
        value.should.eql(z: [2, 3, 1])
    ]

  describe 'map', ->

    promiseIt 'map values', () ->
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
          value.should.eql({a: transformMap.map.dog, b: transformMap.map.cat, c: transformMap.map.bigCat})
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

  describe 'mapKeys', ->

    promiseIt 'works', () ->
      orig =
        params:
          id: 1
          notes_id: 3
      [
        expectResolve validateAndTransform orig,
          params: validators.mapKeys(id: 'user_project.id', notes_id: 'user_notes.id')
        .then (value) ->
          value.should.eql
            params:
              'user_project.id': 1
              'user_notes.id': 3
      ]
