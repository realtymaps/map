Promise = require 'bluebird'
{basePath} = require '../../globalSetup'

{validators, DataValidationError, validateAndTransform} = require "#{basePath}/utils/util.validation"
{expectResolve, expectReject, promiseIt} = require('../../../specUtils/promiseUtils')
cls = require 'continuation-local-storage'
{NAMESPACE} = require "#{basePath}/config/config"

describe 'utils/validation.validators.reqId', () ->

  describe 'reqId', () ->

    promiseIt 'works', () ->

      new Promise (resolve, reject) -> Promise.try ->

        namespace = cls.createNamespace(NAMESPACE)
        namespace.run -> #test must be inside of run as that is the namespaces lifespan
          namespace.set 'req',
            user:
              id: 3

          expectResolve validateAndTransform {},
            params: validators.reqId(toKey: 'auth_user_id')
          .then (value) ->
            value.should.eql params: auth_user_id: 3
            resolve()
