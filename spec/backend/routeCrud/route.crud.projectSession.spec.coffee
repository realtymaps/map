require '../../globals'
expect = require('chai').expect
require 'should'
Promise = require 'bluebird'
basePath = require '../basePath'
sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
{toTestableCrudInstance, toTestThenableCrudInstance} = require "#{basePath}/utils/crud/util.crud.service.helpers"
userServices = require("#{basePath}/services/services.user")

sqlHelpers = require "#{basePath}/utils/util.sql.helpers"
safeProject = sqlHelpers.columns.project
rewire = require 'rewire'
routeCrudToTest = rewire "#{basePath}/routeCrud/route.crud.projectSession"

testableProjSvc = toTestableCrudInstance userServices.project,
  getAll: ->
    # console.log "testableProjSvc: getAll"
    [id:1]


userSvc = routeCrudToTest.__get__('userSvc')

#needed since a route is mixing with route and svc logic... ugh
testableClientsSvc = toTestThenableCrudInstance userSvc.clients,
  getAll: ->
    console.log "testableClientsSvc: getAll"
    [client_id:2]

userSvc.clients = testableClientsSvc

# console.log userSvc.clients, true

routeCrudToTest.__set__ 'userSvc', userSvc

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
        console.log '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
        console.log out.sql
        console.log out.clients.sql
