Promise = require 'bluebird'
{basePath} = require '../../globalSetup'

validation = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')


describe 'utils/validation.validators.bathrooms()'.ns().ns('Backend'), ->
  param = 'fake'

  promiseIt 'should nullify empty values', () ->
    [
      expectResolve(validation.validators.bathrooms()(param, null)).then (value) ->
        (value == null).should.be.true
      expectResolve(validation.validators.bathrooms()(param, {})).then (value) ->
        (value == null).should.be.true
    ]

  promiseIt 'should use full and half values when given', () ->
    [
      expectResolve(validation.validators.bathrooms()(param, {full: 2, half: 0, total: 4.8})).then (value) ->
        value.label.should.equal('Baths (Full / Half)')
        value.value.should.equal('2 / 0')
        value.filter.should.equal(2.0)
      expectResolve(validation.validators.bathrooms()(param, {full: 2, half: 1, total: 4.8})).then (value) ->
        value.label.should.equal('Baths (Full / Half)')
        value.value.should.equal('2 / 1')
        value.filter.should.equal(2.5)
    ]

  promiseIt 'should fall back to total value if needed', () ->
    [
      expectResolve(validation.validators.bathrooms()(param, {full: 2, total: 3.0})).then (value) ->
        value.label.should.equal('Baths')
        value.value.should.equal('3.0')
        value.filter.should.equal(3.0)
      expectResolve(validation.validators.bathrooms()(param, {full: 2, total: 3.5})).then (value) ->
        value.label.should.equal('Baths')
        value.value.should.equal('3.5')
        value.filter.should.equal(3.5)
    ]

  promiseIt 'should normalize filter value to at most .5 from half', () ->
    [
      expectResolve(validation.validators.bathrooms()(param, {full: 2, half: 2})).then (value) ->
        value.label.should.equal('Baths (Full / Half)')
        value.value.should.equal('2 / 2')
        value.filter.should.equal(2.5)
      expectResolve(validation.validators.bathrooms()(param, {full: 2, total: 3.1})).then (value) ->
        value.label.should.equal('Baths')
        value.value.should.equal('3.1')
        value.filter.should.equal(3.5)
      expectResolve(validation.validators.bathrooms()(param, {full: 2, total: 3.9})).then (value) ->
        value.label.should.equal('Baths')
        value.value.should.equal('3.9')
        value.filter.should.equal(3.5)
    ]
