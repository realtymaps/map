_ = require 'lodash'
require('chai').should()
sinon = require 'sinon'
rewire = require 'rewire'
Promise = require 'bluebird'
{basePath} = require '../globalSetup'
SqlMock = require '../../specUtils/sqlMock'

internals = rewire "#{basePath}/routes/route.onboarding.internals"
onboardingRoute = rewire "#{basePath}/routes/route.onboarding"

logger = require("../../specUtils/logger").spawn('backend:route:onboarding')

subject = null
# onboardingRoute.__set__ 'mergeHandles', ->

setInternal = (obj) ->
  createPasswordHashStub = sinon.stub().returns(Promise.resolve('password'))

  internals.__set__ 'emailServices', {}
  internals.__set__ 'mlsAgentService',
    exists: () ->
      Promise.resolve(true)
  internals.__set__ 'paymentServices', {}

  internals.__set__ 'userSessionService',
    createPasswordHash: createPasswordHashStub
  internals.__set__ 'tables', @tablesStubs
  internals.__set__ 'planService',
    getPlanId: () ->
      logger.debug -> "FAKE CUSTOMER CREATED"
      Promise.resolve(1)


  for k,v of obj
    logger.debug -> "internals[k] = v #{k}"
    #sketchy as I need to set both public and private
    internals[k] = v
    internals.__set__ k, v

  logger.debug -> internals

  onboardingRoute.__set__ 'internals', internals

describe "route.onboarding", ->

  beforeEach ->
    @res =
      json: sinon.stub()
    @next = sinon.stub()

    validateAndTransformRequestStub = sinon.stub()

    sqlMocks =
      user: new SqlMock 'auth', 'user'
      m2m_user_group: new SqlMock 'auth', 'm2m_user_group'
      m2m_user_locations: new SqlMock 'auth', 'm2m_user_locations'
      m2m_user_mls: new SqlMock 'auth', 'm2m_user_mls'


    @tablesStubs =
      auth:
        user: sqlMocks.user.dbFn()
        m2m_user_group: sqlMocks.m2m_user_group.dbFn()
        m2m_user_locations: sqlMocks.m2m_user_locations.dbFn()
        m2m_user_mls: sqlMocks.m2m_user_mls.dbFn()

    sqlMocks.user.setResults [
      {id:1, first_name: "first", last_name: "last"}
      [id:1, first_name: "second", last_name: "2Last"]
    ]
    sqlMocks.m2m_user_group.setResult([])
    sqlMocks.m2m_user_locations.setResult([])
    sqlMocks.m2m_user_mls.setResult([])

    @transactionThenStub = sinon.stub()
    @transactionCatchStub = sinon.stub()

    @transaction = (dbName, trxQueryCb) =>
      Promise.try () ->
        logger.debug.cyan "trxQueryCb!!!!!!!!!!!!!!!!!!"
        trxQueryCb({})
      .then () =>
        logger.debug.magenta "THEN!!!!!!!!!!!!!!!!!!"
        @transactionThenStub()
      .catch (error) =>
        logger.debug.yellow error
        logger.debug.magenta "CATCH!!!!!!!!!!!!!!!!!!"
        @transactionCatchStub()

    onboardingRoute.__set__ 'wrapHandleRoutes', ({handles}) ->
      handles
    onboardingRoute.__set__ 'dbs',
      transaction: @transaction

    onboardingRoute.__set__ 'validateAndTransformRequest', (req) -> Promise.try ->
      validateAndTransformRequestStub()
      req

    subject = onboardingRoute.__get__ 'handles'



  describe 'createUser', ->
    beforeEach ->
      @mockReq =
        params: {}
        query:{}
        body:
          first_name: "first"
          last_name: "last"
          plan:
            name: 'pro'
          token: 'token'
          fips_code: 'fips_code'
          mls_code: 'mls_code'
          mls_id: 'mls_id'

    describe "submitPaymentPlan", ->

      it 'on reject error transaction catches', ->
        setInternal.call @,
          submitPaymentPlan: () ->
            logger.debug "PAYMENT CALLED"
            Promise.reject(new Error 'PLANNED')

          submitEmail: () ->
            logger.debug "EMAIL CALLED"
            Promise.resolve()

          setNewUserMapPosition: () ->
            logger.debug "setNewUserMapPosition CALLED"
            Promise.resolve()

        subject.createUser(@mockReq, @res, @next)
        .then =>
          @transactionCatchStub.called.should.be.true

      it 'on resolve transaction resolves', ->
        setInternal.call @,
          submitPaymentPlan: () ->
            logger.debug "PAYMENT CALLED"
            Promise.resolve(authUser:{}, customer:{})

          submitEmail: () ->
            logger.debug "EMAIL CALLED"
            Promise.resolve()

          setNewUserMapPosition: () ->
            logger.debug "setNewUserMapPosition CALLED"
            Promise.resolve()

        subject.createUser(@mockReq, @res, @next)
        .then =>
          @transactionThenStub.called.should.be.true

    describe "submitEmail", ->

      it 'on reject error transaction catches', ->
        setInternal.call @,
          submitPaymentPlan: () ->
            logger.debug "PAYMENT CALLED"
            Promise.resolve(authUser:{}, customer:{})

          submitEmail: () ->
            logger.debug "EMAIL CALLED"
            Promise.reject(new Error('PLANNED'))

          setNewUserMapPosition: () ->
            logger.debug "setNewUserMapPosition CALLED"
            Promise.resolve()


        subject.createUser(@mockReq, @res, @next)
        .then =>
          @transactionCatchStub.called.should.be.true

      it 'on resolve transaction resolves', ->
        setInternal.call @,
          submitPaymentPlan: () ->
            logger.debug "PAYMENT CALLED"
            Promise.resolve(authUser:{}, customer:{})

          submitEmail: () ->
            logger.debug "EMAIL CALLED"
            Promise.resolve()

          setNewUserMapPosition: () ->
            logger.debug "setNewUserMapPosition CALLED"
            Promise.resolve()
        subject.createUser(@mockReq, @res, @next)
        .then =>
          @transactionThenStub.called.should.be.true
