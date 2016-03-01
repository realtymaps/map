{basePath} = require '../backendUnit/globalSetup'
logger = require("./logger").spawn('crudServiceMock')
{dbFnCalls} = require "#{basePath}/utils/crud/util.crud.service.helpers"
sinon = require 'sinon'
SqlMock = require './sqlMock'


#wraps a crud instance to return all db functions as sql query or a sql payload object
#TODO: Overwrite @dbFn with SqlMock
toTestableCrudInstance = (crudInstance, mockResponse, doRetAsPromise, doLog) ->
  _initLogger = logger.spawn("init")
  _initLogger.debug '\n\narguments:'
  _initLogger.debug "crudInstance.dbFn.tableName: #{crudInstance.dbFn.tableName}"
  _initLogger.debug "mockResponse: #{JSON.stringify(mockResponse)}"
  _initLogger.debug "doRetAsPromise: #{doRetAsPromise}"
  _initLogger.debug 'crudInstance.dbFn() instanceof SqlMock?'
  _initLogger.debug crudInstance.dbFn() instanceof SqlMock

  for fnName in dbFnCalls
    do (fnName) ->
      origFn = crudInstance[fnName]
      stub = crudInstance[fnName + 'Stub'] = sinon.stub()
      if crudInstance?.logger?.namespace
        fnNameLog = logger.spawn("#{fnName}:#{crudInstance.logger.namespace}")
      else
        fnNameLog = logger.spawn(fnName)
      stub.sqls = []
      crudInstance[fnName] = () ->
        potentialKnexPromise = origFn.apply(crudInstance, arguments)
        maybeSql = potentialKnexPromise.toString()


        fnNameLog.debug "\n\n#{fnName}: maybeSql, potentialKnexPromise:"
        fnNameLog.debug maybeSql
        fnNameLog.debug potentialKnexPromise

        if maybeSql != "[object Promise]"
          calledSql = maybeSql

        unless mockResponse?[fnName]
          fnNameLog.debug "\n\nreturning stub calledSql:"
          fnNameLog.debug calledSql
          stub.returns(calledSql)
          return stub(arguments...)

        resp = mockResponse[fnName]
        stub.sqls.push calledSql

        stubLogger = fnNameLog.spawn("stub")
        stubLogger.debug '\n\nstub.sqls, mockResponse, resp, fnName:'
        stubLogger.debug stub.sqls
        stubLogger.debug "mockResponse[#{fnName}]"
        stubLogger.debug resp, true
        stubLogger.debug fnName

        stub.returns(resp)
        resp =  stub(arguments...)

        if doRetAsPromise
          fnNameLog.debug "doRetAsPromise"
          fnNameLog.debug resp
          return Promise.resolve resp

        fnNameLog.debug "resp"
        fnNameLog.debug resp
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
