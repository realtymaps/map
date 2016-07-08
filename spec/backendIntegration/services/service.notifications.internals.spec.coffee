Promise = require 'bluebird'
_ = require 'lodash'
tables = require '../../../backend/config/tables'
dbs = require '../../../backend/config/dbs'
subject = require '../../../backend/services/service.notifications.internals'
logger = require('../../../backend/config/logger').spawn('service:notifications:internals')
require("chai").should()
uuid = require 'node-uuid'
testKey = 'integration_spec_notifications'

makeFakeUser = (first_name, last_name, email = '@gmail.com') ->
  unique = uuid.v4().split('-')
  unique = unique[unique.length-1]
  {
    first_name
    last_name
    email: unique + email
    is_active: false
    password: uuid.v4()
    username: testKey
  }


getCounts = (transaction, cb) ->
  Promise.join tables.auth.user({transaction}).count()
  , tables.user.profile({transaction}).count()
  , tables.user.project({transaction}).count()
  , cb

describe 'service.notifications.internals', ->
  describe 'distribute', ->
    after ->
      tables.auth.user()
      .where username: testKey
      .delete()
      .then () =>
        getCounts undefined, (@userCntEnd, @profileCntEnd, @projectCntEnd) =>
          logger.debug [@userCntEnd, @profileCntEnd, @projectCntEnd], true
          ['user', 'profile', 'project'].forEach (name) =>
            if @[name+'Cnt'].count != @[name+'CntEnd'].count
              throw new Error "COUNT MISMATCH: #{name}Cnt: #{@[name+'Cnt']}, #{name}CntEnd: #{@[name+'CntEnd']}"

    before ->

      dbs.transaction (transaction) =>

        tables.auth.user({transaction}) #only need to delete users as foreign keys clean the rest yay
        .where username: testKey
        .delete()
        .then () =>
          getCounts transaction, (@userCnt, @profileCnt, @projectCnt) =>
            logger.debug [@userCnt, @profileCnt, @projectCnt], true

        .then () =>
          #dummy accounts
          users = [
            makeFakeUser('Mc', 'Daddy')
            makeFakeUser('twoFirst', 'twoLast')
            makeFakeUser('threeFirst', 'threeLast')
          ]

          @emails = [users[1].email, users[2].email]


          tables.auth.user({transaction})
          .insert users
          .returning('id')
          .then (rows) =>
            logger.debug "Fake users created"
            logger.debug rows
            @userIds = rows
            logger.debug @userIds
          .then () =>
            tables.auth.user({transaction})
            .select('id')
            .where {first_name: 'Mc', last_name: 'Daddy'}
            .then ([parent]) =>
              @parentId = parent.id
              logger.debug "Fake parentId: #{@parentId}"
              #make a project for them all to belong to and owned by the Parent
              tables.user.project({transaction})
              .insert {
                name: testKey
                auth_user_id: parent.id
              }
              .returning('id')
              .then ([id]) =>
                logger.debug "Fake project created, id: #{id}"
                @projectId = id
                @projectId
          .then (project_id) =>
            logger.debug "@parentId"
            logger.debug @parentId
            logger.debug "@userIds"
            logger.debug @userIds
            @childrenIds = _.without @userIds, @parentId

            logger.debug @childrenIds
            profiles = @childrenIds.map (id) =>
              {auth_user_id:id, project_id, parent_auth_user_id: @parentId}

            logger.debug "Attempting insert of Profiles"
            logger.debug profiles
            #make profiles
            tables.user.profile({transaction})
            .insert profiles
            .returning 'id'
            .then (rows) =>
              @profileIds = _.pluck rows, 'id'
              logger.debug "profiles inserted ids: #{@profileIds}"
              logger.debug "!!!!!!!!! DONE SETUP !!!!!!!!!"



    describe 'from parent', ->

      it 'getChildUsers works', ->
        logger.debug @parentId
        logger.debug @projectId
        subject.distribute.getChildUsers {id:@parentId, project_id: @projectId}
        .then (rows) =>
          rows.length.should.be.eql 2
          rows[0].email.should.be.eql @emails[0]
          rows[1].email.should.be.eql @emails[1]

      describe 'getUsers', ->
        it 'all', ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['all'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 2

        it "['all', 'self']", ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['all', 'self'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 3

        it 'parents', ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['parents'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 0

        it ['parents', 'self'], ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['parents', 'self'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 1

        it 'children', ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['children'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 2

        it "['children', 'self']", ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['children', 'self'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 3

        it 'self', ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['self'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 1

        it 'invalid', ->
          logger.debug @parentId
          subject.distribute.getUsers {to: ['invalid'], id: @parentId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 0

    describe 'from child', ->

      it 'getParentUsers works', ->
        logger.debug @parentId
        logger.debug childId = @childrenIds[0]
        subject.distribute.getParentUsers {id:childId, project_id: @projectId}
        .then (rows) ->
          rows.length.should.be.eql 1

      it 'getSiblingUsers works', ->
        logger.debug @parentId
        logger.debug childId = @childrenIds[0]
        subject.distribute.getSiblingUsers {id:childId, project_id: @projectId}
        .then (rows) =>
          logger.debug "@@@@ ROWS @@@@"
          logger.debug rows
          rows.length.should.be.eql 1
          rows[0].id.should.be.eql @childrenIds[1]

      describe 'getUsers', ->
        it 'all', ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: 'all', id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 2

        it "['all', 'self']", ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: ['all', 'self'], id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 3

        it 'parents', ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: 'parents', id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 1

        it "['parents', 'self']", ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: ['parents', 'self'], id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 2

        it 'children', ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: 'children', id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 0

        it "['children', 'self']", ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: ['children', 'self'], id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 1

        it 'self', ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: ['self'], id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 1

        it 'invalid', ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: ['invalid'], id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 0

        it 'undefined', ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: undefined, id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 0

        it 'null', ->
          logger.debug @parentId
          logger.debug childId = @childrenIds[0]
          subject.distribute.getUsers {to: null, id: childId, project_id: @projectId}
          .then (rows) ->
            rows.length.should.be.eql 0
