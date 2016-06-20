sinon = require 'sinon'
{expect, should} = require("chai")
should()
rewire = require 'rewire'
subject = rewire '../../../backend/services/service.notification.queue'
SqlMock = require '../../specUtils/sqlMock.coffee'

describe "service.notification.queue", ->
  tables = null

  before () ->
    userNotify = new SqlMock 'user', 'notificationQueue'
    userConfig = new SqlMock 'user', 'notificationConfig'
    authUser = new SqlMock 'auth', 'user'

    makeTable = (thing) ->
      f = () ->
        thing
      f.tableName = thing.tableName
      f

    tables =
      user:
        notificationQueue: makeTable userNotify

        notificationConfig: makeTable userConfig
      auth:
        user: makeTable authUser


    subject.__set__ 'tables', tables


  it 'instance is defined', () ->
    subject.instance.should.be.ok

  describe 'override instance', () ->
    beforeEach ->
      subject.instance.dbFn = tables.user.notificationQueue

    it 'runs getAllWithConfigUser', () ->
      new subject.instance.getAllWithConfigUser()
      .then (rows) ->
