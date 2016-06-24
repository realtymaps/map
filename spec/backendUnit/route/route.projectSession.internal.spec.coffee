{assert, expect, should} = require('chai')
should()
Promise = require 'bluebird'
{basePath} = require '../globalSetup'
logger = require("../../specUtils/logger").spawn('route.crud.projectSession')
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
CrudServiceHelpers = require "#{basePath}/utils/crud/util.crud.service.helpers"
ServiceCrud = CrudServiceHelpers.Crud
{toTestThenableCrudInstance} = require "../../specUtils/crudServiceMock"
{sqlMock} = require "../../specUtils/sqlMock"
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
rewire = require 'rewire'
routeCrudToTest = rewire "#{basePath}/routes/route.projectSession.internal"
safeProject = sqlHelpers.columns.project
mockCls = require '../../specUtils/mockCls'
{joinColumnNames} = require "#{basePath}/utils/util.sql.columns"
tables = require "#{basePath}/config/tables"
sinon = require 'sinon'
require "#{basePath}/extensions"
_ = require 'lodash'

ServiceCrudProject = rewire "#{basePath}/services/service.user.project"

projectResponses =
  getAll:[id:1]
  getById: [id:1, sandbox: false]
  delete: 1

 notesResponses = clientResponses = profilesResponses =
  delete: 1
  getAll: [{project_id:1, id:2}]

drawnShapesRsponses =
  delete: 1
  getAll: [{project_id:1, draw_id:1, id:2, shape_extras:{}}]

userUtils =
  cacheUserValues: sinon.stub()

profileSvc =
  getAll: () ->
    Promise.resolve(profilesResponses.getAll)
  getAllBulk: () ->
    Promise.resolve(profilesResponses.getAll)
  delete: () -> profilesResponses.delete

routeCrudToTest.__set__ 'userUtils', userUtils
routeCrudToTest.__set__ 'profileSvc', profileSvc
ServiceCrudProject.__set__ 'profileSvc', profileSvc

mockRes =
  json: ->

class TestServiceCrudProject extends ServiceCrudProject
  constructor: () ->
    super sqlMock('user', 'project').dbFn()

  #overide the generators so we can inject fresh mocks without destroying the singleton tables
  clientsFact: () ->
    clientAuthMock = sqlMock('auth', 'user')
    clientProfileMock = sqlMock('user', 'profile')
    clientsSvcCrud = super(clientAuthMock.dbFn(), new ServiceCrud(clientProfileMock.dbFn()))
    #expose service mocks on the svc object
    _.extend clientsSvcCrud, {clientAuthMock, clientProfileMock}
    clientsSvcCrud
    # console.log.cyan  "clientsSvcCrud: #{clientsSvcCrud.dbFn().tableName}"
    # console.log.cyan  "clientsSvcCrud: joinCrud: #{clientsSvcCrud.joinCrud.dbFn().tableName}"

    clientsSvcCrud.resetSpies = () =>
      @svc.resetSpies()
      @joinCrud.svc.resetSpies()


    toTestThenableCrudInstance clientsSvcCrud, clientResponses, false

  notesFact: () ->
    noteProjectMock = sqlMock('user', 'project')
    noteMock = sqlMock('user', 'notes')

    noteSvcCrud = super noteProjectMock.dbFn(), new ServiceCrud(noteMock.dbFn())
    #expose service mocks on the svc object
    _.extend noteSvcCrud, {noteProjectMock, noteMock}
    noteSvcCrud.resetSpies = () =>
      @svc.resetSpies()
      @joinCrud.svc.resetSpies()

    # console.log.cyan  "noteSvcCrud: #{noteSvcCrud.dbFn().tableName}"
    # console.log.cyan  "noteSvcCrud: joinCrud: #{noteSvcCrud.joinCrud.dbFn().tableName}"

    toTestThenableCrudInstance noteSvcCrud, notesResponses

  drawnShapesFact: () ->
    drawSvcCrud = super(sqlMock('user', 'drawnShapes').dbFn())
    # console.log.cyan  "drawSvcCrud: #{drawSvcCrud.dbFn().tableName}"
    toTestThenableCrudInstance drawSvcCrud, drawnShapesRsponses

  profilesFact: () ->
    profileSvcCrud = super sqlMock('user', 'project').dbFn(), new ServiceCrud(sqlMock('user', 'profile').dbFn())
    profileSvcCrud.resetSpies = () =>
      @svc.resetSpies()
      @joinCrud.svc.resetSpies()

    # console.log.cyan  "profileSvcCrud: #{profileSvcCrud.dbFn().tableName}"
    # console.log.cyan  "profileSvcCrud: joinCrud: #{profileSvcCrud.joinCrud.dbFn().tableName}"

    toTestThenableCrudInstance profileSvcCrud, profilesResponses


  resetSpies: () ->
    #RESET UNDERLYING dbFn spies
    @svc.resetSpies()#(true, 'deleteStub')
    @clients.resetSpies()#(true, 'deleteStub')
    @notes.resetSpies()
    @drawnShapes.svc.resetSpies()
    @profiles.svc.resetSpies()

  resetStubs: () ->
    #RESET SvcCrud Stubs
    @resetStubs()#(true, 'deleteStub')
    @clients.resetStubs()#(true, 'deleteStub')
    @notes.resetStubs()
    @drawnShapes.resetStubs()
    @profiles.resetStubs()



#END BEGIN TESTABLE OVERRIDES

describe 'route.projectSession', ->

  afterEach ->
    @projCrudSvc.resetStubs()
    @cls.kill()

  beforeEach ->

    @cls = mockCls()
    @makeRequest = (req) =>
      throw new Error("NEED MockRequest") unless req
      @cls.addItem 'req', req
      @mockRequest = req

    @ctor = routeCrudToTest
    @projCrudSvc = toTestThenableCrudInstance new TestServiceCrudProject().init(false,false,false), projectResponses, false

    @subject = new @ctor(@projCrudSvc).init(false, safeProject)

  it 'ctor', ->
    @ctor.should.be.ok

  it 'instance exists', ->
    @subject.should.be.ok

  describe 'rootGET', ->
    beforeEach ->
      @makeRequest
        user:
          id: 2
        params:
          id:1
        query:{}
        body:{}

    it 'project', ->
      @subject.rootGET(@mockRequest,mockRes,(->))
      .then (projects) =>
        @subject.svc.getAllStub.sqls.should.be.ok
        @subject.svc.getAllStub.sqls[0].should.be.eql """select * from "user_project" where "id" = '1' and "auth_user_id" = '2'"""
        logger.debug.green @subject.svc.getAllStub.args[0], true
        @subject.svc.getAllStub.args[0][0].should.be.eql
          id:1
          auth_user_id: 2
        @subject.svc.getAllStub.args[0][1].should.be.eql false

        # console.log.cyan projects, true
        projects.length.should.be.ok
        projects[0].clients.length.should.be.ok
        projects[0].notes.length.should.be.ok
        # console.log.cyan projects[0].drawnShapes, true
        projects[0].drawnShapes.length.should.be.ok

  #   it 'clients', ->
  #     @subject.rootGET(@mockRequest,mockRes,(->))
  #     .then () =>
  #       @subject.clientsCrud.svc.getAllStub.args.length.should.be.ok
  #       obj = {}
  #       obj[joinColumnNames.client.project_id] = [@mockRequest.params.id]
  #       @subject.clientsCrud.svc.getAllStub.args[0][0].should.be.eql obj
  #       logger.debug.green @subject.clientsCrud.svc.getAllStub.sqls[0]
  #
  #       #note that if we add more project_id's then they will be in whereIn
  #       @subject.clientsCrud.svc.clientProfileMock
  #       .whereSpy.args.should.be.eql  [
  #         ['user_profile.project_id', 1 ]
  #       ]
  #       @subject.clientsCrud.svc.clientProfileMock
  #       .whereInSpy.args.should.be.eql []
  #
  #
    it 'notes', ->
      @subject.rootGET(@mockRequest,mockRes,(->))
      .then () =>
        @subject.notesCrud.svc.getAllStub.args.length.should.be.ok
        obj = {}
        #TODO: SHOULD notes be restricted to project only or also to parent_auth_user_id, or auth_user_id
        # obj.parent_auth_user_id = @mockRequest.user.id
        obj["#{tables.user.notes.tableName}.project_id"] = [ @mockRequest.params.id ]
        @subject.notesCrud.svc.getAllStub.args[0][0].should.be.eql obj
        @subject.notesCrud.svc.getAllStub.args[0][1].should.be.eql false
        assert.isTrue @subject.notesCrud.svc.getAllStub.sqls.length > 0

        @subject.notesCrud.svc.noteMock.whereSpy.args.should.eql [
          [ 'user_notes.project_id', 1 ]
        ]

        @subject.notesCrud.svc.noteMock.whereInSpy.args.length.should.be.equal 0
  #
  #
  #   it 'drawnShapes', ->
  #     @subject.rootGET(@mockRequest,mockRes,(->))
  #     .then () =>
  #       @subject.drawnShapesCrud.svc.getAllStub.args.length.should.be.ok
  #       params =
  #         project_id: [ @mockRequest.params.id ]
  #       #TODO: SHOULD notes be restricted to project only or also to parent_auth_user_id, or auth_user_id
  #       # obj.parent_auth_user_id = @mockRequest.user.id
  #       @subject.drawnShapesCrud.svc.getAllStub.args[0][0].should.be.eql params
  #       expect(@subject.drawnShapesCrud.svc.getAllStub.args[0][1]).to.not.be.ok
  #
  # describe 'byIdDELETE', ->
  #   beforeEach ->
  #     @makeRequest
  #       session:
  #         saveAsync: -> Promise.resolve()
  #         profiles: []
  #       user:
  #         id: 2
  #       params:
  #         id:1
  #       query:{}
  #       body:{}
  #
  #   it 'clients', ->
  #     @subject.byIdDELETE(@mockRequest,mockRes,(->))
  #     .then =>
  #       @subject.svc.deleteStub.called.should.be.true
  #       userUtils.cacheUserValues.called.should.be.ok
  #       assert.ok @subject.clientsCrud.svc.deleteStub.sqls
