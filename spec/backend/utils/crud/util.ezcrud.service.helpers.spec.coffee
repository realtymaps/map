_ = require 'lodash'
basePath = require '../../basePath'
sinon = require "sinon"
SqlMock = require '../../../specUtils/sqlMock'
ServiceCrud = require "#{basePath}/utils/crud/util.ezcrud.service.helpers"

describe 'util.ezcrud.service.helpers', ->

  describe 'ServiceCrud', ->
    beforeEach ->
      @dbFn = new SqlMock 'config', 'dataSourceFields'
      @serviceCrud = new ServiceCrud(@dbFn)

    it 'passes sanity check', ->
      ServiceCrud.should.be.ok
      @serviceCrud.should.be.ok

    it 'fails instantiation without dbFn', ->
      (-> new ServiceCrud()).should.throw()

    #it 'passes '




    # @serviceCrud.exposeKnex().customGet().knex 

