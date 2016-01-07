basePath = require '../backend/basePath'
logger = require("#{basePath}/config/logger").spawn('test:crudServiceMock')
{dbFnCalls} = require "#{basePath}/utils/crud/util.crud.service.helpers"
sinon = require 'sinon'
SqlMock = require './sqlMock'
# Promise = require 'bluebird'

#logger = loggerLib.spawn('test:crudServiceMock')
console.log "\n\n##### Logger keys:"
console.log Object.keys(logger)
logger.debug "\n\n##### (logger.debug) crudServiceMock evaluated"
logger.log "\n\n##### (logger.log) crudServiceMock evaluated"
console.log "\n\n##### (console.log) crudServiceMock evaluated"

#wraps a crud instance to return all db functions as sql query or a sql payload object
#TODO: Overwrite @dbFn with SqlMock
toTestableCrudInstance = (crudInstance, mockResponse, doRetAsPromise, doLog) ->
  # if doLog
    # logger.debug.green 'arguments:'
    # logger.debug.cyan "crudInstance.dbFn.tableName: #{crudInstance.dbFn.tableName}"
    # logger.debug.cyan "mockResponse: #{JSON.stringify(mockResponse)}"
    # logger.debug.cyan "doRetAsPromise: #{doRetAsPromise}"
    # logger.debug.green 'crudInstance.dbFn() instanceof SqlMock?'
    # logger.debug.cyan crudInstance.dbFn() instanceof SqlMock

  for fnName in dbFnCalls
    do (fnName) ->
      origFn = crudInstance[fnName]
      stub = crudInstance[fnName + 'Stub'] = sinon.stub()
      stub.sqls = []
      crudInstance[fnName] = () ->
        potentialKnexPromise = origFn.apply(crudInstance, arguments)
        maybeSql = potentialKnexPromise.toString()

        if doLog
          logger.debug.green "#{fnName}: maybeSql, potentialKnexPromise:"
          logger.debug.cyan maybeSql
          logger.debug.red potentialKnexPromise

        if maybeSql != "[object Promise]"
          calledSql = maybeSql

        unless mockResponse?[fnName]
          if doLog
            logger.debug.green "returning stub calledSql:"
            logger.debug.cyan calledSql
          stub.returns(calledSql)
          return stub(arguments...)

        resp = mockResponse[fnName]
        stub.sqls.push calledSql
        if doLog
          logger.debug.green 'stub.sqls, mockResponse, resp, fnName:'
          logger.debug.cyan stub.sqls
          logger.debug.cyan "mockResponse[#{fnName}]"
          logger.debug.cyan resp, true
          logger.debug.cyan fnName
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
  #logger.debug "\n\n##### toTestableCrudInstance"
  toTestableCrudInstance(crudInstance, mockResponse, true, doLog)

module.exports =
  toTestableCrudInstance: toTestableCrudInstance
  toTestThenableCrudInstance: toTestThenableCrudInstance
