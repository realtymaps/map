require("chai").should()
Promise = require 'bluebird'
{basePath} = require '../globalSetup'
_ = require 'lodash'
require("chai").should()
{expect} = require("chai")
sinon = require 'sinon'
logger = require('../../specUtils/logger').spawn('validation')

{
validators
validateAndTransform
validateAndTransformRequest
DataValidationError
defaultRequestTransforms
falsyTransformsToNoop
requireAllTransforms
notRequired
} = require "#{basePath}/utils/util.validation"

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

  describe "transform.any", ->

    promiseIt 'should pass if any validations in the "any" array pass validation, even if some fail', () ->
      expectResolve validateAndTransform {a: 'abc'},
        a: transform: any: [validators.integer(), validators.string(forceUpperCase: true)]
      .then (values) ->
        values.should.eql(a: 'ABC')

    promiseIt 'should fail if all validations in the "any" array fail validation', () ->
      expectReject validateAndTransform {a: 'abc'},
        a: transform: any: [validators.integer(),validators.object()]
      , DataValidationError

  describe "rooted input", ->

    promiseIt 'basic', () ->
      expectResolve validateAndTransform {a: 'abc'},
        a: {input: false}
      .then (values) ->
        values.should.eql(a: a: 'abc')

    promiseIt 'fipsCode', () ->
      expectResolve validateAndTransform {fipsCode: 'abc'},
        fips_code:
          transform: validators.fips()
          input: false
      .then (values) ->
        values.should.eql(fips_code: 'abc')


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

  describe 'defaultRequestTransforms', ->
    it 'undefined', ->
      res = defaultRequestTransforms()
      for key,val of res
        val.should.be.eql validators.noop
    it 'has query params body', ->
      res = defaultRequestTransforms()
      for val in ['query', 'params', 'body']
        res[val].should.be.eql validators.noop
    it 'null', ->
      res = defaultRequestTransforms(null)
      for key,val of res
        val.should.be.eql validators.noop
    it 'false', ->
      res = defaultRequestTransforms(false)
      for key,val of res
        val.should.be.eql validators.noop

    describe 'partial', ->
      ['query', 'body', 'params'].forEach (reqName) ->
        it "not #{reqName}", ->
          matchValidator = validators.string()
          obj = {}
          obj[reqName] = matchValidator
          res = defaultRequestTransforms(obj)
          for key,val of res
            if key != reqName
              val.should.be.eql validators.noop
            else
              val.should.be.eql matchValidator

  describe 'falsyTransformsToNoop', ->
    it 'undefined', ->
      expect(falsyTransformsToNoop()).to.not.be.ok

    it 'partial obj transforms def', ->
      tForm = validators.string()
      ret = falsyTransformsToNoop
        query: tForm
        params: null
      ret.query.should.be.eql tForm
      ret.params.should.be.eql validators.noop
      expect(ret.body).to.not.be.ok

describe 'utils/validation.validateAndTransformRequest()'.ns().ns('Backend'), ->
  promiseIt "should omit missing parameters", () ->
    [
      expectResolve validateAndTransformRequest {a: 'abc'},
        a: validators.string(forceUpperCase: true)
        b: validators.float()
      .then (values) ->
        values.should.eql({a: 'ABC'})
    ]

describe 'requireAllTransforms', ->
  it 'should add required field of true to all fields', ->
    obj =
      test1: () ->
      test2: () ->

    allRequiredTforms = requireAllTransforms obj

    _.keys(allRequiredTforms).should.have.lengthOf(2)

    for key, val of allRequiredTforms
      # console.log key
      val.required.should.be.ok
      val.transform.should.be.ok

  it 'should add not require excludes', ->
    obj =
      test1: () ->
      test2: () ->

    allRequiredTforms = requireAllTransforms obj, ['test2']

    _.keys(allRequiredTforms).should.have.lengthOf(2)


    allRequiredTforms.test1.transform.should.be.a('function')
    allRequiredTforms.test1.required.should.be.true
    allRequiredTforms.test2.should.be.a('function')
    expect(allRequiredTforms.test2.required).to.not.be.ok

  it 'should add not require via notRequired', ->
    obj =
      test1: () ->
      test2: notRequired () ->

    logger.debug obj, true

    allRequiredTforms = requireAllTransforms obj

    logger.debug allRequiredTforms, true

    _.keys(allRequiredTforms).should.have.lengthOf(2)


    allRequiredTforms.test1.transform.should.be.a('function')
    allRequiredTforms.test1.required.should.be.true
    allRequiredTforms.test2.should.be.a('function')
    expect(allRequiredTforms.test2.required).to.not.be.ok
