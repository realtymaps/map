_ = require 'lodash'
sinon = require 'sinon'
{basePath} = require '../../globalSetup'
{validators} = require "#{basePath}/utils/util.validation"
RouteCrud = require "#{basePath}/utils/crud/util.ezcrud.route.helpers"
ServiceCrud = require "#{basePath}/utils/crud/util.ezcrud.service.helpers"
{expect} = require 'chai'
require('chai').should()

makeRequest = (method) ->
  request =
    method: method
    params: {id: 1}
    body: {lorem: "ipsum"}

describe 'util.ezcrud.route.helpers', ->
  describe 'RouteCrud', ->
    beforeEach ->
      @svcMock = sinon.createStubInstance(ServiceCrud);

      @routeCrud = new RouteCrud(@svcMock, {debugNS:'testRoute'})
      sinon.stub(@routeCrud, '_wrapRoute').returns(true)
      sinon.spy(@routeCrud, 'validRequest')

    it 'passes sanity check', ->
      RouteCrud.should.be.ok
      @routeCrud.should.be.ok

    it 'partial defaults noop validation', (done) ->
      request = makeRequest('GET')
      @routeCrud.rootGETTransforms =
        query: validators.noop
      @routeCrud.validRequest(request, 'rootGET')
      .then (tReq) =>
        # comparing the JSON of tReq to filter out parts of that object not worth comparing here
        expect(JSON.stringify tReq).to.eql '{"params":{"id":1},"body":{"lorem":"ipsum"}}'
        done()

    it 'fails instantiation without svc', ->
      (-> new RouteCrud(null, {quiet: true})).should.throw()

    it 'produces a "tReq" and combines params and body', (done) ->
      @routeCrud.getEntity(makeRequest()).then (entity) ->
        expect(entity).to.deep.equal {"id":1,"lorem":"ipsum"}
        done()

    it 'performs root GET', (done) ->
      request = makeRequest('GET')
      @routeCrud.root(request, {}, ->).then =>
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.getAll.calledOnce.should.be.true
        @svcMock.create.called.should.be.false
        done()

    it 'performs root POST', (done) ->
      request = makeRequest('POST')
      @routeCrud.root(request, {}, ->).then =>
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.getAll.called.should.be.false
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.create.calledOnce.should.be.true
        done()

    it 'performs byId GET', (done) ->
      request = makeRequest('GET')
      @routeCrud.byId(request, {}, ->).then =>
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.getAll.called.should.be.false
        @svcMock.getById.calledOnce.should.be.true
        @svcMock.create.called.should.be.false
        @svcMock.update.called.should.be.false
        @svcMock.upsert.called.should.be.false
        @svcMock.delete.called.should.be.false
        done()

    it 'performs byId PUT', (done) ->
      request = makeRequest('PUT')
      @routeCrud.byId(request, {}, ->).then =>
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.getAll.called.should.be.false
        @svcMock.getById.called.should.be.false
        @svcMock.create.called.should.be.false
        @svcMock.update.calledOnce.should.be.true
        @svcMock.upsert.called.should.be.false
        @svcMock.delete.called.should.be.false
        done()

    it 'performs byId POST', (done) ->
      request = makeRequest('POST')
      @routeCrud.byId(request, {}, ->).then =>
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.getAll.called.should.be.false
        @svcMock.getById.called.should.be.false
        @svcMock.create.calledOnce.should.be.true
        @svcMock.update.called.should.be.false
        @svcMock.upsert.called.should.be.false
        @svcMock.delete.called.should.be.false
        done()

    it 'performs byId DELETE', (done) ->
      request = makeRequest('DELETE')
      @routeCrud.byId(request, {}, ->).then =>
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.getAll.called.should.be.false
        @svcMock.getById.called.should.be.false
        @svcMock.create.called.should.be.false
        @svcMock.update.called.should.be.false
        @svcMock.upsert.called.should.be.false
        @svcMock.delete.calledOnce.should.be.true
        done()

    it 'performs byId POST, upsert', (done) ->
      request = makeRequest('POST')
      @routeCrud.enableUpsert = true
      @routeCrud.byId(request, {}, ->).then =>
        @routeCrud.validRequest.calledOnce.should.be.true
        @svcMock.getAll.called.should.be.false
        @svcMock.getById.called.should.be.false
        @svcMock.create.called.should.be.false
        @svcMock.update.called.should.be.false
        @svcMock.upsert.calledOnce.should.be.true
        @svcMock.delete.called.should.be.false
        done()
