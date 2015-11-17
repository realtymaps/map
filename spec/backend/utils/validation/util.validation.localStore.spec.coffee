Promise = require 'bluebird'
basePath = require '../../basePath'

{validators, DataValidationError, validateAndTransform} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')
cls = require 'continuation-local-storage'
{NAMESPACE} = require "#{basePath}/config/config"

describe 'utils/validation.validators.localStore', () ->

  describe 'localStore', () ->

    promiseIt 'works', () ->

      new Promise (resolve, reject) -> Promise.try ->

        namespace = cls.createNamespace(NAMESPACE)
        namespace.run -> #test must be inside of run as that is the namespaces lifespan
          namespace.set 'orig',
            params:
              id: 1
              notes_id: 3

          expectResolve validateAndTransform {},
            params: validators.localStore(clsKey: 'orig.params.notes_id', toKey: 'notes_id')
          .then (value) ->
            value.should.eql params: notes_id: 3
            resolve()
