sinon = require 'sinon'
{expect, should} = require("chai")
should()
rewire = require 'rewire'
subject = rewire '../../../backend/services/service.notification.config'
SqlMock = require '../../specUtils/sqlMock.coffee'
tables = null
userNotifyConfig = null

makeTable = (thing) ->
  f = () ->
    thing
  f.tableName = thing.tableName
  f

# describe 'real', ->
#   it 'crap', ->
#     subject.instance.getAllWithUser(id: 8)
#     .then (rows) ->
#       console.log rows

describe "service.notification.config", ->

  beforeEach ->
    userNotifyConfig = new SqlMock 'user', 'notificationConfig'
    authUser = new SqlMock 'auth', 'user'

    tables =
      auth:
        user: makeTable authUser
      user:
        notificationConfig: makeTable userNotifyConfig

    subject.__set__ 'tables', tables

  it 'instance is defined', () ->
    subject.instance.should.be.ok

  describe 'basic queies work', () ->
    beforeEach ->
      subject.instance.dbFn = tables.user.notificationConfig

    it 'explicit id', () ->
      subject.instance.getAllWithUser("user_notification_config.id": 1)
      userNotifyConfig.selectSpy.called.should.be.ok
      userNotifyConfig.whereSpy.called.should.be.ok
      userNotifyConfig.innerJoinSpy.called.should.be.ok
      userNotifyConfig.whereSpy.args.should.be.eql [[{"user_notification_config.id": 1}]]

    it 'id', () ->
      subject.instance.getAllWithUser(id: 1)
      userNotifyConfig.selectSpy.called.should.be.ok
      userNotifyConfig.whereSpy.called.should.be.ok
      userNotifyConfig.innerJoinSpy.called.should.be.ok
      userNotifyConfig.whereSpy.args.should.be.eql [[{"user_notification_config.id": 1}]]
