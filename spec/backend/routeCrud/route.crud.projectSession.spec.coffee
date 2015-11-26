require '../../globals'
{assert} = require('chai')
Promise = require 'bluebird'
require 'should'
basePath = require '../basePath'
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
CrudServiceHelpers = require "#{basePath}/utils/crud/util.crud.service.helpers"
ServiceCrud = CrudServiceHelpers.Crud
{toTestThenableCrudInstance} = require "../../specUtils/util.crud.service.test.helpers"
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
rewire = require 'rewire'
routeCrudToTest = rewire "#{basePath}/routeCrud/route.crud.projectSession"
safeProject = sqlHelpers.columns.project
mockCls = require '../../specUtils/mockCls'
{joinColumnNames} = require "#{basePath}/utils/util.sql.columns"
tableNames = require("#{basePath}/config/tableNames")
usrTableNames = tableNames.user
sinon = require 'sinon'
require "#{basePath}/extensions"
mockKnex = require 'mock-knex'
colorWrap = require 'color-wrap'
colorWrap(console)
{dbFnFactory, dbFnsFactory} = require("#{basePath}/config/tables")
{knexFactory} = require("#{basePath}/config/dbs")

ServiceCrudProject = rewire "#{basePath}/services/service.user.project"

projectResponses =
  getAll:[id:1]
  getById: [id:1, sandbox: false]
  delete: 1

drawnShapesRsponses = notesResponses = clientResponses =
  delete: 1
  getAll: [{project_id:1, id:2}]


class TestServiceCrudProject extends ServiceCrudProject
  constructor: (@db) ->
    super dbFnFactory(@db, tableNames.user.project)

  #overide the generators so we can inject fresh mocks without destroying the singleton tables
  clientsFact: () ->
    toTestThenableCrudInstance(
      super(dbFnFactory(@db, tableNames.auth.user),
      new ServiceCrud(dbFnFactory(@db, tableNames.user.profile))),
      clientResponses
    )

  notesFact: () ->
    toTestThenableCrudInstance(
      super(dbFnFactory(@db, tableNames.user.notes),
      new ServiceCrud(dbFnFactory(@db, tableNames.user.project))),
      notesResponses
    )

  drawnShapesFact: () ->
    toTestThenableCrudInstance(super(dbFnFactory(@db, tableNames.user.drawnShapes)), drawnShapesRsponses)

  resetAllStubs: () ->
    @resetStubs()#(true, 'deleteStub')
    @clients.resetStubs()#(true, 'deleteStub')
    @notes.resetStubs()
    @drawnShapes.resetStubs()

#BEGIN TESTABLE OVERRIDES
testDb = knexFactory('main')

userUtils =
  cacheUserValues: sinon.stub()

ServiceCrudProject.__set__ 'userUtils', userUtils


#END BEGIN TESTABLE OVERRIDES

describe 'route.projectSession', ->
  afterEach ->
    @projCrudSvc.resetAllStubs()
    @cls.kill()

  beforeEach ->

    @cls = mockCls()
    @makeRequest = (req) =>
      throw new Error("NEED MockRequest") unless req
      @cls.addItem 'req', req
      @mockRequest = req

    @ctor = routeCrudToTest
    @projCrudSvc = toTestThenableCrudInstance new TestServiceCrudProject(testDb), projectResponses

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
      @subject.rootGET(@mockRequest)
      .then (projects) =>
        @subject.svc.getAllStub.sqls.should.be.ok
        @subject.svc.getAllStub.sqls[0].should.be.eql """select * from "user_project" where "id" = '1' and "auth_user_id" = '2'"""
        console.log @subject.svc.getAllStub.args[0], true
        @subject.svc.getAllStub.args[0][0].should.be.eql
          id:1
          auth_user_id: 2
        @subject.svc.getAllStub.args[0][1].should.be.eql false

        # console.log.cyan projects, true
        projects.length.should.be.ok
        projects[0].clients.length.should.be.ok
        projects[0].notes.length.should.be.ok
        projects[0].drawnShapes.length.should.be.ok

    it 'clients', ->
      @subject.rootGET(@mockRequest)
      .then () =>
        @subject.clientsCrud.svc.getAllStub.args.length.should.be.ok
        obj = {}
        obj.parent_auth_user_id = @mockRequest.user.id
        obj[joinColumnNames.client.project_id] = [@mockRequest.params.id]
        @subject.clientsCrud.svc.getAllStub.args[0][0].should.be.eql obj
        console.log @subject.clientsCrud.svc.getAllStub.sqls[0]
        @subject.clientsCrud.svc.getAllStub.sqls[0].should.be.equal """
        select "user_profile"."id" as "id", "user_profile"."auth_user_id" as "auth_user_id",
         "user_profile"."parent_auth_user_id" as "parent_auth_user_id", "user_profile"."project_id" as "project_id",
         "auth_user"."email" as "email", "auth_user"."first_name" as "first_name", "auth_user"."last_name" as "last_name",
         "auth_user"."username" as "username", "auth_user"."address_1" as "address_1", "auth_user"."address_2" as "address_2",
         "auth_user"."city" as "city", "auth_user"."zip" as "zip",
         "auth_user"."us_state_id" as "us_state_id", "auth_user"."cell_phone" as "cell_phone",
         "auth_user"."work_phone" as "work_phone", "auth_user"."parent_id" as "parent_id" from
         "user_profile" inner join "auth_user" on "auth_user"."id" = #{sqlHelpers.sqlizeColName joinColumnNames.client.auth_user_id}
         where #{sqlHelpers.sqlizeColName joinColumnNames.client.project_id} in ('1') and "parent_auth_user_id" = '2'
        """.replace(/\n/g,'')

    it 'notes', ->
      @subject.rootGET(@mockRequest)
      .then () =>
        @subject.notesCrud.svc.getAllStub.args.length.should.be.ok
        obj = {}
        #TODO: SHOULD notes be restricted to project only or also to parent_auth_user_id, or auth_user_id
        # obj.parent_auth_user_id = @mockRequest.user.id
        obj["#{usrTableNames.notes}.project_id"] = @mockRequest.params.id
        @subject.notesCrud.svc.getAllStub.args[0][0].should.be.eql obj
        @subject.notesCrud.svc.getAllStub.args[0][1].should.be.eql false
        assert.isTrue @subject.notesCrud.svc.getAllStub.sqls.length > 0
        @subject.notesCrud.svc.getAllStub.sqls[0].should.be.equal """
          select "user_notes"."id" as "id", "user_notes"."auth_user_id" as "auth_user_id",
           "user_notes"."project_id" as "project_id", "user_notes"."rm_property_id" as "rm_property_id",
           "user_notes"."geom_point_json" as "geom_point_json", "user_notes"."comments" as "comments",
           "user_notes"."text" as "text", "user_notes"."title" as "title" from "user_project"
           inner join "user_notes" on "user_notes"."project_id" = "user_project"."id" where
           "user_notes"."project_id" = '1'""".replace(/\n/g,'')

    it 'drawnShapes', ->
      @subject.rootGET(@mockRequest)
      .then () =>
        @subject.drawnShapesCrud.svc.getAllStub.args.length.should.be.ok
        params = {}
        #TODO: SHOULD notes be restricted to project only or also to parent_auth_user_id, or auth_user_id
        # obj.parent_auth_user_id = @mockRequest.user.id
        params["#{usrTableNames.drawnShapes}.project_id"] = @mockRequest.params.id
        @subject.drawnShapesCrud.svc.getAllStub.args[0][0].should.be.eql params
        @subject.drawnShapesCrud.svc.getAllStub.args[0][1].should.be.eql false
        # assert.isTrue @subject.drawnShapesCrud.svc.getAllStub.sqls.length > 0
        # # console.log @subject.drawnShapesCrud.svc.getAllStub.sqls[0].cyan
        # @subject.drawnShapesCrud.svc.getAllStub.sqls[0].should.be.equal """
        #   select "user_drawn_shapes"."id" as "id", "user_drawn_shapes"."auth_user_id" as "auth_user_id",
        #    "user_drawn_shapes"."project_id" as "project_id", "user_drawn_shapes"."geom_point_json" as "geom_point_json",
        #    "user_drawn_shapes"."geom_polys_raw" as "geom_polys_raw" from "user_project" inner join "user_drawn_shapes"
        #    on "user_drawn_shapes"."project_id" = "user_project"."id" where "user_drawn_shapes"."project_id" = '1'
        #    """.replace(/\n/g,'')

  describe 'byIdDELETE', ->
    beforeEach ->
      @makeRequest
        session:
          saveAsync: -> Promise.resolve()
        user:
          id: 2
        params:
          id:1
        query:{}
        body:{}

    # it 'clients', ->
    #   mockKnex.mock(testDb)
    #   @projCrudSvc = toTestThenableCrudInstance new TestServiceCrudProject(testDb), projectResponses
    #   @subject = new @ctor(@projCrudSvc).init(false, safeProject)
    #   # dbFns = dbFnsFactory db, _.zipObject [
    #   #   'auth_user', usrTableNames.project, usrTableNames.profile, usrTableNames.drawnShapes, usrTableNames.notes]
    #   # console.log.cyan dbFns, true
    #   # @subject.svc.dbFn = dbFns.user_project
    #   # @subject.svc.clients.dbFn = dbFns.auth_user
    #   # @subject.svc.clients.joinCrud.dbFn = dbFns.user_profile
    #   # @subject.svc.drawnShapes.dbFn = dbFns.user_drawn_shapes
    #   # @subject.svc.notes.dbFn = dbFns.user_notes
    #   # @subject.svc.notes.joinCrud.dbFn = dbFns.project
    #   # console.log.green @subject, true
    #   tracker = mockKnex.getTracker()
    #   tracker.install()
    #
    #   tracker.on 'query', (query) ->
    #     switch query.method
    #       when 'select'#satisfy getById
    #         console.log.blue 'select called'
    #         query.response projectResponses.getById
    #       when 'del'
    #         console.log.cyan 'delete called'
    #         query.response clientResponses.delete
    #       else
    #         console.log.blue 'unhandled query method: ' + query.method
    #         query.response []
    #
    #   @subject.byIdDELETE(@mockRequest)
    #   .then =>
    #     @subject.clientsCrud.svc.deleteStub.called.should.be.true
    #     userUtils.cacheUserValues.called.should.be.ok
    #     assert.ok @subject.clientsCrud.svc.deleteStub.sqls
    #     # assert.ok @subject.clientsCrud.svc.deleteStub.sqls.length
    #     # assert.notOk @subject.clientsCrud.svc.deleteStub.sqls[0]
    #     # assert.ok @subject.clientsCrud.svc.deleteStub.knexPromises[0]
    #     # @subject.clientsCrud.svc.deleteStub.knexPromises[0].then (result) ->
    #     #   assert.isTrue result
    #     # @subject.clientsCrud.svc.deleteStub.knexPromises[0]
    #
    #   .finally ->
    #     console.log.green "BEGIN UMOCK"
    #     tracker.uninstall()
    #     mockKnex.unmock(db)
    #     console.log.green "UMOCK SUCCESS"
