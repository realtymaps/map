should = require 'should'
mainSubject = require ('../../../../../backend/utils/crud/extensions/util.crud.extension.user.coffee')
dummyReq = null


describe 'util.crud.extensions.user', ->
  describe 'route', ->
    beforeEach ->
      @subject = mainSubject.route
      dummyReq =
        user:
          id: 'crap'

    it 'exists', ->
      @subject.should.be.ok

    describe 'withUser', ->
      beforeEach ->
        @subject = mainSubject.route.withUser

      it 'exists', ->
        @subject.should.be.ok

      describe 'args', ->
        describe 'req only', ->
          it 'extend an empty object', ->
            @subject dummyReq, (test) ->
              test.auth_user_id.should.be.equal dummyReq.user.id
              Object.keys(test).length.should.be.equal 1


          it 'extends req.query', ->
            dummyReq.query =
              dummy: 'dummy'

            @subject dummyReq, (test) ->
              test.auth_user_id.should.be.equal dummyReq.user.id
              Object.keys(test).length.should.be.equal 2
              test.dummy.should.be.equal dummyReq.query.dummy

          it 'req, toBeQueryClause, cb w, toBeQueryClause as Object uses req.body', ->
            dummyReq.body =
              dummy: 'dummy'

            @subject dummyReq, dummyReq.body, (test) ->
              test.auth_user_id.should.be.equal dummyReq.user.id
              Object.keys(test).length.should.be.equal 2
              test.dummy.should.be.equal dummyReq.body.dummy

          describe 'no callback', ->
            it 'extend an empty object', ->
              dummyReq.query =
                dummy: 'dummy'

              @subject dummyReq
              dummyReq.query.auth_user_id.should.be.equal dummyReq.user.id
              Object.keys(dummyReq.query).length.should.be.equal 2
