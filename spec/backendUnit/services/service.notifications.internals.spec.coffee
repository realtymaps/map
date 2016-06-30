sinon = require 'sinon'
{expect, should} = require("chai")
should()
Promise = require 'bluebird'
rewire = require 'rewire'
require '../../../common/extensions/strings'
subject = rewire '../../../backend/services/service.notifications.internals'
SqlMock = require '../../specUtils/sqlMock.coffee'
logger = require('../../specUtils/logger').spawn('service:notifications:internals')
_ = require 'lodash'
veroEventsFn = require '../../../backend/services/email/vero/service.email.impl.vero.events'
stubbedVeroEvents = null

describe "service.notifications.internals", ->

  before () ->
    userNotify = new SqlMock 'user', 'notificationQueue'

    tables =
      user:
        notificationQueue: userNotify.dbFn

    subject.__set__ 'tables', tables

  describe 'sendEmailVero', () ->
    before () ->
      # logger.debug "@@@@@@@@@ veroEvents @@@@@@@@@"
      veroEvents = veroEventsFn()
      # logger.debug veroEvents
      stubbedVeroEvents = sinon.stub veroEvents

      subject.__set__ 'promisedVeroService', Promise.resolve events: stubbedVeroEvents

    it 'called with pinned', () ->
      row =
        config_notification_id: 1
        first_name: 'Mike'
        last_name: 'Jordan'

      options =
        type: 'propertySaved'

      subject.sendEmailVero(row, options)
      .then () ->
        stubbedVeroEvents.notificationPropertiesSaved.called.should.be.ok

  describe 'distribute', ->
    describe 'getUsers', ->
      stubs = null
      describe 'matches', ->
        beforeEach ->
          stubs =
            children: sinon.stub()
            parents: sinon.stub()
          subject.__set__ 'getChildUsers', stubs.children
          subject.__set__ 'getParentUsers', stubs.parents

        ['children','parents','all'].forEach (name) ->
          it name, ->
            subject.distribute.getUsers to: name

            if name != 'all'
              stubs[name].called.should.be.ok
            else
              stubs.children.called.should.be.ok
              stubs.parents.called.should.be.ok
