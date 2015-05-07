{CARTODB} = require '../../../backend/config/config'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.cartodb'

describe 'service.cartodb', ->
  beforeEach ->
    @subject = svc
    @limitStub = sinon.stub()
    @sqlHelpersMock =
      select: sinon.stub().returns
        from: sinon.stub().returns
          where: sinon.stub().returns
            whereNotNull: sinon.stub().returns
              orderBy: sinon.stub().returns
                limit: @limitStub
                then: sinon.stub()
                stream: sinon.stub()


    @subject.__set__ sqlHelpers: @sqlHelpersMock


  describe 'restful', ->
    describe 'getByFipsCode', ->
      describe 'runs', ->
        it 'no limit', ->
          @subject.restful.getByFipsCode
            api_key: CARTODB.API_KEY_TO_US
            fipscode: 12011
          @sqlHelpersMock.select.calledOnce.should.equal true

        it 'limit', ->
          @subject.restful.getByFipsCode
            api_key: CARTODB.API_KEY_TO_US
            fipscode: 12011
            limit: 10
          @sqlHelpersMock.select.calledOnce.should.equal true
          @limitStub.calledOnce.should.equal true

      describe 'throws', ->
        it 'api_key', ->
          expect(@subject.restful.getByFipsCode).to.throw('UNAUTHORIZED')
        it 'fips_code', ->
          fn = =>
            @subject.restful.getByFipsCode(api_key: CARTODB.API_KEY_TO_US)
          expect(fn).to.throw('BADREQUEST')
