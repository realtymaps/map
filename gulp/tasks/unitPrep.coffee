gulp = require 'gulp'
Promise = require 'bluebird'
universalMock = require '../../spec/specUtils/universalMock'
dbs = require '../../backend/config/dbs'


gulp.task 'unitTestPrep', (done) ->
  dbs.disable()

  externalAccounts = require "../../backend/services/service.externalAccounts"
  accounts =
    vero:
      other:
        auth_token: ''
    stripe:
      other:
        secret_test_api_key: ''
        secret_live_api_key: ''
    twilio:
      username: 'asdf'
      api_key: 'asdf'
      other:
        number: '+12223334444'
  universalMock.mock externalAccounts, 'getAccountInfo', (acctName) ->
    Promise.resolve(accounts[acctName])

  keystore = require "../../backend/services/service.keystore"
  store =
    __null_key__: {}
    time_limits:
      email_minutes: 15
  getValue = (key, opts={}) ->
    namespace = opts.namespace ? '__null_key__'
    defaultValue = opts.defaultValue ? undefined
    Promise.resolve(store[namespace]?[key] ? defaultValue)
  universalMock.mock keystore, 'getValue', getValue
  universalMock.mock keystore.cache, 'getValue', getValue
  getValuesMap = (namespace, opts={}) ->
    Promise.resolve(store[namespace] ? opts.defaultValues)
  universalMock.mock keystore, 'getValuesMap', getValuesMap
  universalMock.mock keystore.cache, 'getValuesMap', getValuesMap

  done()

gulp.task 'unitTestTeardown', (done) ->
  dbs.enable()
  universalMock.resetAll()
  done()
