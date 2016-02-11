basePath = require '../backendUnit/basePath'
logger = require("./logger").spawn('crudServiceMock')
{dbFnCalls} = require "#{basePath}/utils/crud/util.crud.service.helpers"
sinon = require 'sinon'
SqlMock = require './sqlMock'


#wraps a crud instance to return all db functions as sql query or a sql payload object
#TODO: Overwrite @dbFn with SqlMock
toTestableCrudInstance = (crudInstance, mockResponse, doRetAsPromise, doLog) ->
  if doLog
    logger.debug '\n\narguments:'
    logger.debug "crudInstance.dbFn.tableName: #{crudInstance.dbFn.tableName}"
    logger.debug "mockResponse: #{JSON.stringify(mockResponse)}"
    logger.debug "doRetAsPromise: #{doRetAsPromise}"
    logger.debug 'crudInstance.dbFn() instanceof SqlMock?'
    logger.debug crudInstance.dbFn() instanceof SqlMock

  for fnName in dbFnCalls
    do (fnName) ->
      origFn = crudInstance[fnName]
      stub = crudInstance[fnName + 'Stub'] = sinon.stub()
      stub.sqls = []
      crudInstance[fnName] = () ->
        potentialKnexPromise = origFn.apply(crudInstance, arguments)
        maybeSql = potentialKnexPromise.toString()

        if doLog
          logger.debug "\n\n#{fnName}: maybeSql, potentialKnexPromise:"
          logger.debug maybeSql
          logger.debug potentialKnexPromise

        if maybeSql != "[object Promise]"
          calledSql = maybeSql

        unless mockResponse?[fnName]
          if doLog
            logger.debug "\n\nreturning stub calledSql:"
            logger.debug calledSql
          stub.returns(calledSql)
          return stub(arguments...)

        resp = mockResponse[fnName]
        stub.sqls.push calledSql
        if doLog
          logger.debug '\n\nstub.sqls, mockResponse, resp, fnName:'
          logger.debug stub.sqls
          logger.debug "mockResponse[#{fnName}]"
          logger.debug resp, true
          logger.debug fnName
        stub.returns(resp)
        resp =  stub(arguments...)
        return Promise.resolve resp if doRetAsPromise
        resp

  crudInstance.resetStubs = (doLog, stubNameToLog) ->
    for fnName in dbFnCalls
      do (fnName) ->
        stubName = fnName + 'Stub'
        if stubNameToLog
          doLog = stubNameToLog == stubName
        if doLog
          logger.debug "\n\n#{stubName}"
          logger.debug crudInstance, true
        crudInstance[stubName].reset()
        crudInstance[stubName].sqls = []

  crudInstance

toTestThenableCrudInstance = (crudInstance, mockResponse, doLog) ->
  toTestableCrudInstance(crudInstance, mockResponse, true, doLog)

module.exports =
  toTestableCrudInstance: toTestableCrudInstance
  toTestThenableCrudInstance: toTestThenableCrudInstance
