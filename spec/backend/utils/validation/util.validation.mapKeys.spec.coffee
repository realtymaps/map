Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError, validateAndTransform} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')

describe 'utils/validation.validators.mapKeys()', () ->

  describe 'mapKeys', () ->

    promiseIt 'maps all', () ->
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

    promiseIt 'passes through unmapped props', () ->
      orig =
        params:
          id: 1
          notes_id: 3
      [
        expectResolve validateAndTransform orig,
          params: validators.mapKeys(id: 'user_project.id')
        .then (value) ->
          value.should.eql
            params:
              'user_project.id': 1
              notes_id: 3
      ]
