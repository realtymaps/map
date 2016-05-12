_ =  require 'lodash'
require("chai").should()
rewire = require 'rewire'
emailTransforms = rewire '../../../../backend/utils/transforms/transforms.email'
SqlMock = require '../../../specUtils/sqlMock'
{validateAndTransformRequest} = require '../../../../backend/utils/util.validation'
transforms = require '../../../../backend/utils/transforms/transforms.userSession'
routeInternals = require '../../../../backend/routes/route.userSession.internals'
cls = require 'continuation-local-storage'
{NAMESPACE} = require '../../../../backend/config/config'

emailTransforms.__set__ 'tables',
  auth:
    user: new SqlMock 'auth', 'user', result: [
      id: 1
      first_name: "Bo"
      last_name: "Jackson"
      email: "boknows@gmail.com"
      email_validation_hash: "radarIsJammed"
      cancel_email_hash: "terminated"
    ]

describe 'transforms.userSession', ->
  describe 'root', ->
    describe 'PUT has correct fields', ->
      toOmit = [
        'id'
        'account_image_id'
        'company_id'
        'parent_id'
      ]
      validationFields = _.difference routeInternals.safeUserFields, toOmit

      beforeEach ->

        namespace = cls.createNamespace(NAMESPACE)
        namespace.run => #test must be inside of run as that is the namespaces lifespan
          namespace.set 'req',
            user:
              id: 3

          @validBodyPromise = validateAndTransformRequest
            first_name: 'Mc'
            last_name: 'Lovin'
            address_1: '100 Junk Rd.'
            address_2: 'Apt 100'
            city: 'crap'
            us_state_id: 2
            zip: 24501
            cell_phone: '5555556622'
            work_phone: '555-555-6622'
            username: 'bootsraped'
            website_url: "http://crap.com"
            email: "crap@gmail.com"
            account_use_type_id: 1
          , transforms.root.PUT()

      validationFields.forEach (key) ->
        it key, ->
          @validBodyPromise.then (validObj) ->
            exists = Object.keys(validObj).indexOf(key) >= 0
            exists.should.be.ok
