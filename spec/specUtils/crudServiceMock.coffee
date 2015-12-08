basePath = require '../backend/basePath'
logger = require "#{basePath}/config/logger"
{dbFnCalls} = require "#{basePath}/utils/crud/util.crud.service.helpers"
sinon = require 'sinon'
# Promise = require 'bluebird'

#wraps a crud instance to return all db functions as sql query or a sql payload object
#TODO: Overwrite @dbFn with SqlMock
toTestableCrudInstance = (crudInstance, mockResponse, doRetAsPromise, doLog) ->
  if doLog
    logger.debug crudInstance, true
    logger.debug "crudInstance: dbFn: #{crudInstance.dbFn}"

  for fnName in dbFnCalls
    do (fnName) ->
      origFn = crudInstance[fnName]
      stub = crudInstance[fnName + 'Stub'] = sinon.stub()
      stub.sqls = []
      crudInstance[fnName] = () ->
        potentialKnexPromise = origFn.apply(crudInstance, arguments)
        maybeSql = potentialKnexPromise.toString()

        # logger.debug.green maybeSql
        # logger.debug.cyan potentialKnexPromise, true

        if maybeSql != "[object Promise]"
          calledSql = maybeSql

        unless mockResponse?[fnName]
          stub.returns(calledSql)
          return stub(arguments...)

        resp = mockResponse[fnName]
        stub.sqls.push calledSql
        if doLog
          logger.debug.green stub.sqls
          logger.debug.green "mockResponse[#{fnName}]"
        logger.debug.red resp, true
        logger.debug.red fnName
        stub.returns(resp)
        # console.log arguments, true
        resp =  stub(arguments...)
        return Promise.resolve resp if doRetAsPromise
        resp

  crudInstance.resetStubs = (doLog, stubNameToLog) ->
    for fnName in dbFnCalls
      do (fnName) ->
        # logger.debug crudInstance[fnName + 'Stub']
        stubName = fnName + 'Stub'
        if stubNameToLog
          doLog = stubNameToLog == stubName
        if doLog
          logger.debug stubName
          logger.debug crudInstance, true
        crudInstance[stubName].reset()
        crudInstance[stubName].sqls = []

  crudInstance

toTestThenableCrudInstance = (crudInstance, mockResponse, doLog) ->
  toTestableCrudInstance(crudInstance, mockResponse, true, doLog)

module.exports =
  toTestableCrudInstance: toTestableCrudInstance
  toTestThenableCrudInstance: toTestThenableCrudInstance
