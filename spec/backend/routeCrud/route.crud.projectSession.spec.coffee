require '../../globals'
expect = require('chai').expect
assert = require('chai').assert
sinon = require 'sinon'
require 'should'
Promise = require 'bluebird'
basePath = require '../basePath'
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
{toTestableCrudInstance, toTestThenableCrudInstance} = require "../../specUtils/util.crud.service.test.helpers"
userServices = require("#{basePath}/services/services.user")

sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
safeProject = sqlHelpers.columns.project
rewire = require 'rewire'
routeCrudToTest = rewire "#{basePath}/routeCrud/route.crud.projectSession"
safeNotes = sqlHelpers.columns.notes
safeProfile = sqlHelpers.columns.profile

#BEGIN TESTABLE OVERRIDES
testableProjSvc = toTestableCrudInstance userServices.project,
  getAll:[id:1]
  getById: Promise.resolve [id:1, sandbox: false]
  delete: true


userSvc = routeCrudToTest.__get__('userSvc')
profileSvc = routeCrudToTest.__get__('profileSvc').clone()
notesSvc = routeCrudToTest.__get__('notesSvc').clone()

#needed since a route is mixing with route and svc logic... ugh
testableClientsSvc = toTestThenableCrudInstance userSvc.clients,
  getAll: [{project_id:1, client_id:2}]

testableProfileSvc = toTestThenableCrudInstance profileSvc,
  delete: true

testableNotesSvc = toTestThenableCrudInstance notesSvc,
  delete: true

# console.log userSvc.clients, true
userSvc.clients = testableClientsSvc
routeCrudToTest.__set__ 'userSvc', userSvc
routeCrudToTest.__set__ 'profileSvc', testableProfileSvc
routeCrudToTest.__set__ 'notesSvc', testableNotesSvc

resetAllStubs = () ->
  testableProjSvc.resetStubs()
  testableProfileSvc.resetStubs()#(true, 'deleteStub')
  testableClientsSvc.resetStubs()
  testableNotesSvc.resetStubs()

#END BEGIN TESTABLE OVERRIDES

describe 'route.projectSession', ->
  afterEach ->
    resetAllStubs()
  beforeEach ->
    @ctor = routeCrudToTest
    @subject = new @ctor(testableProjSvc).init(false, safeProject)
    @mockRequest =
      user:
        id: 1
      params:
        id:1
        notes_id:1
        drawn_shapes_id:2
        clients_id:3

  it 'ctor', ->
    @ctor.should.be.ok

  it 'instance exists', ->
    @subject.should.be.ok

  describe 'rootGET', ->
    it 'can run', ->
      @subject.rootGET(@mockRequest)
      .then (out) =>
        @subject.svc.getAllStub.sqls[0].should.be.eql """select * from "user_project" where "id" = '1' and "notes_id" = '1' and "drawn_shapes_id" = '2' and "clients_id" = '3'"""
        console.log out[0].clients, true
        @subject.clientsCrud.svc.getAllStub.sqls[0].should.be.equal """
        select "user_profile"."id" as "id", "user_profile"."auth_user_id" as "auth_user_id",
         "user_profile"."parent_auth_user_id" as "parent_auth_user_id", "user_profile"."project_id" as "project_id",
         "auth_user"."email" as "email", "auth_user"."first_name" as "first_name", "auth_user"."last_name" as "last_name",
         "auth_user"."username" as "username", "auth_user"."address_1" as "address_1", "auth_user"."address_2" as "address_2",
         "auth_user"."city" as "city", "auth_user"."zip" as "zip",
         "auth_user"."us_state_id" as "us_state_id", "auth_user"."cell_phone" as "cell_phone",
         "auth_user"."work_phone" as "work_phone", "auth_user"."parent_id" as "parent_id" from
         "user_profile" inner join "auth_user" on "auth_user"."id" = "user_profile"."auth_user_id" where "project_id" in ('1') and "parent_auth_user_id" = '1'
        """.replace(/\n/g,'')

  describe 'byIdDELETE', ->
    beforeEach ->
      @promise = @subject.byIdDELETE(@mockRequest)

    it 'profileSvc', ->
      @promise.then =>
        testableProfileSvc.deleteStub.called.should.be.true
        testableProfileSvc.deleteStub.sqls[0].should.be.eql """delete from "user_profile" where "auth_user_id" = '1' and "project_id" = '1'"""
        testableProfileSvc.deleteStub.args[0][0].should.be.eql {}
        testableProfileSvc.deleteStub.args[0][1].should.be.eql false
        testableProfileSvc.deleteStub.args[0][2].should.be.eql
          project_id: @mockRequest.params.id
          auth_user_id: @mockRequest.user.id
        testableProfileSvc.deleteStub.args[0][3].should.be.eql safeProfile

    it 'notesSvc', ->
      @promise.then =>
        testableNotesSvc.deleteStub.called.should.be.true
        testableNotesSvc.deleteStub.sqls[0].should.be.eql """delete from "user_notes" where "auth_user_id" = '1' and "project_id" = '1'"""
        testableNotesSvc.deleteStub.args[0][0].should.be.eql {}
        testableNotesSvc.deleteStub.args[0][1].should.be.eql false
        testableNotesSvc.deleteStub.args[0][2].should.be.eql
          project_id: @mockRequest.params.id
          auth_user_id: @mockRequest.user.id
        testableNotesSvc.deleteStub.args[0][3].should.be.eql safeNotes

    it 'super', ->
      testableProjSvc.deleteStub.called.should.be.true
