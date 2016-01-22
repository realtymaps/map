_ = require 'lodash'
sinon = require 'sinon'
basePath = require '../../basePath'
RouteCrud = require "#{basePath}/utils/crud/util.ezcrud.route.helpers"
ServiceCrud = require "#{basePath}/utils/crud/util.ezcrud.service.helpers"
{expect} = require 'chai'

makeRequest = (method) ->
  request =
    method: method
    params: {id: 1}
    body: {lorem: "ipsum"}

describe 'util.ezcrud.route.helpers', ->
  describe 'RouteCrud', ->
    beforeEach ->
      @svcMock = sinon.createStubInstance(ServiceCrud);

      @routeCrud = new RouteCrud(@svcMock)
      sinon.stub(@routeCrud, '_wrapRoute').returns(true)

    it 'passes sanity check', ->
      RouteCrud.should.be.ok
      @routeCrud.should.be.ok

    it 'fails instantiation without svc', ->
      (-> new RouteCrud()).should.throw()

    it 'combines params and body', ->
      query = @routeCrud._getQuery(makeRequest())
      expect(query).to.deep.equal {"id":1,"lorem":"ipsum"}

    it 'performs root GET', ->
      request = makeRequest('GET')
      @routeCrud.root(request, {}, ->)
      @svcMock.getAll.calledOnce.should.be.true
      @svcMock.create.called.should.be.false

    it 'performs root POST', ->
      request = makeRequest('POST')
      @routeCrud.root(request, {}, ->)
      @svcMock.getAll.called.should.be.false
      @svcMock.create.calledOnce.should.be.true

    it 'performs byId GET', ->
      request = makeRequest('GET')
      @routeCrud.byId(request, {}, ->)
      @svcMock.getAll.called.should.be.false
      @svcMock.getById.calledOnce.should.be.true
      @svcMock.create.called.should.be.false
      @svcMock.update.called.should.be.false
      @svcMock.upsert.called.should.be.false
      @svcMock.delete.called.should.be.false

    it 'performs byId PUT', ->
      request = makeRequest('PUT')
      @routeCrud.byId(request, {}, ->)
      @svcMock.getAll.called.should.be.false
      @svcMock.getById.called.should.be.false
      @svcMock.create.called.should.be.false
      @svcMock.update.calledOnce.should.be.true
      @svcMock.upsert.called.should.be.false
      @svcMock.delete.called.should.be.false

    it 'performs byId POST', ->
      request = makeRequest('POST')
      @routeCrud.byId(request, {}, ->)
      @svcMock.getAll.called.should.be.false
      @svcMock.getById.called.should.be.false
      @svcMock.create.calledOnce.should.be.true
      @svcMock.update.called.should.be.false
      @svcMock.upsert.called.should.be.false
      @svcMock.delete.called.should.be.false

    it 'performs byId DELETE', ->
      request = makeRequest('DELETE')
      @routeCrud.byId(request, {}, ->)
      @svcMock.getAll.called.should.be.false
      @svcMock.getById.called.should.be.false
      @svcMock.create.called.should.be.false
      @svcMock.update.called.should.be.false
      @svcMock.upsert.called.should.be.false
      @svcMock.delete.calledOnce.should.be.true

    it 'performs byId POST, upsert', ->
      request = makeRequest('POST')
      @routeCrud.enableUpsert = true
      @routeCrud.byId(request, {}, ->)
      @svcMock.getAll.called.should.be.false
      @svcMock.getById.called.should.be.false
      @svcMock.create.called.should.be.false
      @svcMock.update.called.should.be.false
      @svcMock.upsert.calledOnce.should.be.true
      @svcMock.delete.called.should.be.false
