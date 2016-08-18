{expect, should} = require "chai"
should()
sinon = require "sinon"
Promise = require 'bluebird'
_ = require 'lodash'
{basePath} = require '../../globalSetup'
{Crud, HasManyRouteCrud, wrapRoutesTrait} = require "#{basePath}/utils/crud/util.crud.route.helpers"
crudSvc = require "#{basePath}/utils/crud/util.crud.service.helpers"
{validators} = require "#{basePath}/utils/util.validation"

describe 'util.crud.route.helpers', ->

  beforeEach ->
    @mockQuery =
      query:{}
      body:{}
      params:
        id:'testId'

    @stubbedSvc = sinon.stub(new crudSvc.Crud((->)))

  describe 'Crud', ->
    beforeEach ->
      @subject = new Crud(@stubbedSvc)

    it 'exists', ->
      Crud.should.be.ok

    describe 'constructor', ->

      it 'undefined svc', ->
        (-> new Crud(null, null, null, null, {quiet: true})).should.throw()

      it 'init called', ->
        init = sinon.stub(Crud::, 'init')
        new Crud(@stubbedSvc)
        init.calledOnce.should.be.ok

    describe 'subject', ->
      describe 'validRequest', ->
        it 'defaults noop validation', ->
          @subject.rootGETTransforms = null
          @subject.validRequest(@mockQuery, 'rootGET')
          .then (req) =>
            req.should.be.eql @mockQuery

        it 'partial defaults noop validation', ->
          @subject.rootGETTransforms =
            query: validators.noop
          @subject.validRequest(@mockQuery, 'rootGET')
          .then (req) =>
            req.should.be.eql @mockQuery

      do ->
        args = {doLogQuery: false, safe: undefined}
        [
          {name: 'default', args: args}
          {name: 'doLogQuery', args: _.extend args, doLogQuery: true}
          {name: 'safe', args: _.extend args, safe: [1,2]}
        ].forEach (testObj) ->

          describe "#{testObj.name}", ->
            beforeEach ->
              sinon.stub(@subject, 'validRequest').returns(Promise.resolve(@mockQuery))

            it "exists", ->
              @subject.should.be.ok

            describe "rootGET", ->
              beforeEach ->
                @subject.rootGET @mockQuery

              it "calls svc correctly", ->
                stub = @stubbedSvc.getAll
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery.query, testObj.args.doLogQuery, testObj.args.safe

              it 'calls validRequest correctly', ->
                stub = @subject.validRequest
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery, 'rootGET'

            describe "rootPOST", ->
              beforeEach ->
                @subject.rootPOST @mockQuery

              it "calls svc correctly", ->
                stub = @stubbedSvc.create
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery.body, undefined, testObj.args.doLogQuery

              it 'calls validRequest correctly', ->
                stub = @subject.validRequest
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery, 'rootPOST'

            describe "byIdGET", ->
              beforeEach ->
                @subject.byIdGET @mockQuery

              it "calls svc correctly", ->
                stub = @stubbedSvc.getById
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery.params.id, testObj.args.doLogQuery

              it 'calls validRequest correctly', ->
                stub = @subject.validRequest
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery, 'byIdGET'

            describe "byIdPOST", ->
              beforeEach ->
                @subject.byIdPOST @mockQuery

              it "calls svc correctly", ->
                stub = @stubbedSvc.create
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery.body, @mockQuery.params.id, undefined, testObj.args.doLogQuery

              it 'calls validRequest correctly', ->
                stub = @subject.validRequest
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery, 'byIdPOST'

            describe "byIdDELETE", ->
              beforeEach ->
                @subject.byIdDELETE @mockQuery

              it "calls svc correctly", ->
                stub = @stubbedSvc.delete
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery.params.id, testObj.args.doLogQuery, @mockQuery.query, testObj.args.safe

              it 'calls validRequest correctly', ->
                stub = @subject.validRequest
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery, 'byIdDELETE'

            describe "byIdPUT", ->
              beforeEach ->
                @subject.byIdPUT @mockQuery

              it "calls svc correctly", ->
                stub = @stubbedSvc.update
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery.params.id, @mockQuery.body, testObj.args.safe, testObj.args.doLogQuery

              it 'calls validRequest correctly', ->
                stub = @subject.validRequest
                stub.calledOnce.should.be.ok
                stub.calledWith @mockQuery, 'byIdPUT'

      describe 'sugar', ->
        sugarSet =
          root: ['GET', 'POST']
          byId: ['GET', 'POST', 'DELETE', 'PUT']
        for testName, httpMethods of sugarSet
          do(testName, httpMethods) ->
            describe "#{testName}", ->
              for httpMethod in httpMethods
                do(testName, httpMethod) ->
                  it "#{httpMethod}", ->
                    sinon.stub @subject, testName+httpMethod
                    @mockQuery.method = httpMethod
                    @subject[testName] @mockQuery
                    @subject[testName+httpMethod].called.should.be.ok

  describe 'HasManyRouteCrud', ->
    it 'exists', ->
      HasManyRouteCrud.should.be.ok

    beforeEach ->

      @subject = new HasManyRouteCrud @stubbedSvc, 'crap_id', 'crappy.id'

    describe 'ctor', ->
      it 'basic', ->
        @subject.svc.should.be.eql @stubbedSvc
        @subject.paramIdKey.should.be.eql 'crap_id'

      it 'undefined rootGETKey throws', ->
        (=> new HasManyRouteCrud(@stubbedSvc, null, null, null, null, {quiet: true})).should.throw('@rootGETKey must be defined')

    it 'rootGET', ->
      @subject.rootGET @mockQuery
      .then =>
        stub = @stubbedSvc.getAll
        stub.calledOnce.should.be.ok
        stub.calledWith
          crappy:
            id: 'testId'

  describe 'wrapRoutesTrait', ->
    beforeEach ->
      @subject = wrapRoutesTrait (->)

    it 'exists', ->
      wrapRoutesTrait.should.be.ok

    describe 'handleQuery', ->
      it 'handles a stream', ->
        pipe = sinon.stub()
        mockStream =
          pipe: pipe
          stringify: sinon.stub().returns(pipe:pipe)

        mockRes = {}
        @subject::handleQuery mockStream, mockRes

        mockStream.pipe.calledOnce.should.be.ok
        # mockStream.pipe.calledWith mockRes


      xit 'handles a promise', ->
