require '../../globals'
expect = require('chai').expect
require 'should'
basePath = require '../basePath'
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
{toTestableCrudInstance, toTestThenableCrudInstance} = require "#{basePath}/utils/crud/util.crud.service.helpers"
userServices = require("#{basePath}/services/services.user")

sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
safeProject = sqlHelpers.columns.project
rewire = require 'rewire'
routeCrudToTest = rewire "#{basePath}/routeCrud/route.crud.projectSession"

#BEGIN TESTABLE OVERRIDES
testableProjSvc = toTestableCrudInstance userServices.project,
  getAll: ->
    # console.log "testableProjSvc: getAll"
    [id:1]


userSvc = routeCrudToTest.__get__('userSvc')

#needed since a route is mixing with route and svc logic... ugh
testableClientsSvc = toTestThenableCrudInstance userSvc.clients,
  getAll: (calledSql) ->
    console.log "testableClientsSvc: getAll"
    [{project_id:1, client_id:2, sql: calledSql}]

userSvc.clients = testableClientsSvc

# console.log userSvc.clients, true

routeCrudToTest.__set__ 'userSvc', userSvc

#END BEGIN TESTABLE OVERRIDES

describe 'route.projectSession', ->
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
      .then (out) ->
        out.sql.should.be.eql """select * from "user_project" where "id" = '1' and "notes_id" = '1' and "drawn_shapes_id" = '2' and "clients_id" = '3'"""
        out[0].clients[0].sql.should.be.equal """
        select "user_profile"."id" as "id", "user_profile"."auth_user_id" as "auth_user_id",
         "user_profile"."parent_auth_user_id" as "parent_auth_user_id", "user_profile"."project_id" as "project_id",
         "auth_user"."email" as "email", "auth_user"."first_name" as "first_name", "auth_user"."last_name" as "last_name",
         "auth_user"."username" as "username", "auth_user"."address_1" as "address_1", "auth_user"."address_2" as "address_2",
         "auth_user"."city" as "city", "auth_user"."zip" as "zip",
         "auth_user"."us_state_id" as "us_state_id", "auth_user"."cell_phone" as "cell_phone",
         "auth_user"."work_phone" as "work_phone", "auth_user"."parent_id" as "parent_id" from
         "user_profile" inner join "auth_user" on "auth_user"."id" = "user_profile"."auth_user_id" where "project_id" in ('1') and "parent_auth_user_id" = '1'
        """.replace(/\n/g,'')
