require '../../../globals'
{Crud, HasManyRouteCrud, wrapRoutesTrait} = require '../../../../backend/utils/crud/util.crud.route.helpers'
crudSvc = require '../../../../backend/utils/crud/util.crud.service.helpers'
Promise = require 'bluebird'
_ = require 'lodash'

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
        (-> new Crud()).should.throw()

      it 'init called', ->
        init = sinon.stub(Crud::, 'init')
        new Crud(@stubbedSvc)
        init.calledOnce.should.be.ok

    describe 'subject', ->
      do ->
        args = {doLogQuery: false, safe: undefined}
        [
          {name: 'default', args: args}
          {name: 'doLogQuery', args: _.extend args, doLogQuery: true}
          {name: 'safe', args: _.extend args, safe: [1,2]}
        ].forEach (testObj) ->

          describe "#{testObj.name}", ->
            it "exists", ->
              @subject.should.be.ok

            it "rootGET", ->
              @subject.rootGET @mockQuery

              stub = @stubbedSvc.getAll
              stub.calledOnce.should.be.ok
              stub.calledWith @mockQuery.query, testObj.args.doLogQuery, testObj.args.safe

            it "rootPOST", ->
              @subject.rootPOST @mockQuery

              stub = @stubbedSvc.create
              stub.calledOnce.should.be.ok
              stub.calledWith @mockQuery.body, undefined, testObj.args.doLogQuery

            it "byIdGET", ->
              @subject.byIdGET @mockQuery

              stub = @stubbedSvc.getById
              stub.calledOnce.should.be.ok
              stub.calledWith @mockQuery.params.id, testObj.args.doLogQuery

            it "byIdPOST", ->
              @subject.byIdPOST @mockQuery

              stub = @stubbedSvc.create
              stub.calledOnce.should.be.ok
              stub.calledWith @mockQuery.body, @mockQuery.params.id, undefined, testObj.args.doLogQuery

            it "byIdDELETE", ->
              @subject.byIdDELETE @mockQuery

              stub = @stubbedSvc.delete
              stub.calledOnce.should.be.ok
              stub.calledWith @mockQuery.params.id, testObj.args.doLogQuery, @mockQuery.query, testObj.args.safe

            it "byIdPUT", ->
              @subject.byIdPUT @mockQuery

              stub = @stubbedSvc.update
              stub.calledOnce.should.be.ok
              stub.calledWith @mockQuery.params.id, @mockQuery.body, testObj.args.safe, testObj.args.doLogQuery

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
        @subject.id = 'crap_id'

      it 'undefined rootGETKey throws', ->
        (=> new HasManyRouteCrud @stubbedSvc).should.throw('@rootGETKey must be defined')

    it 'rootGET', ->
      @subject.rootGET @mockQuery

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
