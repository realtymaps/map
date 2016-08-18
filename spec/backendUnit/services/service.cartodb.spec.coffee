rewire = require 'rewire'
svc = rewire '../../../backend/services/service.cartodb'
Promise = require 'bluebird'
require("chai").should()
{expect} = require("chai")
sinon = require 'sinon'

FAKE_API_KEY = 'fake key'
FAKE_API_KEY_TO_US = 'fake key to us'


describe 'service.cartodb', ->
  beforeEach ->
    @subject = svc
    @limitStub = sinon.stub()
    @sqlHelpersMock =
      select: sinon.stub().returns
        where: sinon.stub().returns
          whereNotNull: sinon.stub().returns
            orderBy: sinon.stub().returns
              limit: @limitStub
              then: (handler) -> Promise.try () -> handler()
              stream: sinon.stub()
    @cartodbConfigMock = sinon.stub().returns Promise.resolve
      API_KEY: FAKE_API_KEY
      API_KEY_TO_US: FAKE_API_KEY_TO_US

    @subject.__set__ sqlHelpers: @sqlHelpersMock
    @subject.__set__ cartodbConfig: @cartodbConfigMock
    @subject.__set__ tables: finalized: parcel: () ->


  describe 'restful', ->
    describe 'getByFipsCode', ->
      describe 'runs', ->
        it 'no limit', (done) ->
          @subject.restful.getByFipsCode
            api_key: FAKE_API_KEY_TO_US
            fips_code: 12011
          .then () =>
            @sqlHelpersMock.select.calledOnce.should.equal(true)
            done()

        it 'limit', (done) ->
          @subject.restful.getByFipsCode
            api_key: FAKE_API_KEY_TO_US
            fips_code: 12011
            limit: 10
          .then () =>
            @sqlHelpersMock.select.calledOnce.should.equal(true)
            @limitStub.calledOnce.should.equal(true)
            done()

      describe 'rejects', ->
        it 'api_key', (done) ->
          @subject.restful.getByFipsCode()
          .catch (err) ->
            expect(err.message).to.equal('UNAUTHORIZED')
            done()
        it 'fips_code', (done) ->
          @subject.restful.getByFipsCode(api_key: FAKE_API_KEY_TO_US)
          .catch (err) ->
            expect(err.message).to.equal('BADREQUEST')
            done()
