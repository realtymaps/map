{expect, should} = require("chai")
should()
sinon = require 'sinon'
rewire = require 'rewire'
Promise = require 'bluebird'
_ = require 'lodash'
subject = rewire '../../../backend/services/service.properties.filterSummary'
combined = require '../../../backend/services/service.properties.combined.filterSummary'
logger = require('../../specUtils/logger').spawn('service:properties:filterSummary')


describe "service.properties.filterSummary", ->
  describe 'summary', ->
    validBody = profile = properties = permissions = null
    combinedMock = encodeStub = toLeafletMarkerStub = null
    mainPromise = null

    beforeEach ->

      validBody = {}
      profile =
        id: 1
        pins: _.mapValues
          "12021_01_001": {}
          "12021_02_001": {}
        , (val, key) ->
          rm_property_id: key
          isPinned: true
        favorites: _.mapValues
          "12021_03_001": {}
          "12021_04_001": {}
        , (val, key) ->
          rm_property_id: key
          isFavorite: true

      if !combinedMock
        combinedMock = sinon.stub(combined)
      else
        for key, val of combinedMock
          if _.isFunction val
            val.reset()

      encodeStub = sinon.stub().returns(false)
      toLeafletMarkerStub = sinon.stub()

      permissions = {}
      properties = [
        {rm_property_id:"12021_01_001"}
        {rm_property_id:"12021_02_001"}
        {rm_property_id:"12021_03_001"}
        {rm_property_id:"12021_04_001"}
      ]

      combinedMock.getPermissions.returns(Promise.resolve permissions)
      combinedMock.getFilterSummaryAsQuery.returns(Promise.resolve properties)

      subject.__set__ 'toLeafletMarker', (property) ->
        toLeafletMarkerStub()
        property

      subject.__set__ 'geohash', encode: encodeStub
      subject.__set__ 'combined', combinedMock
      subject.__set__ 'validation',
        validateAndTransform: sinon.stub().returns(Promise.resolve validBody)

      mainPromise = subject.getFilterSummary {
        profile
        validBody
      }

    describe 'savedDetails', ->
      it 'has singletons', ->
        mainPromise
        .then (props) ->
          props.singletons.should.be.ok

      it 'singleton length', ->
        mainPromise
        .then (props) ->
          Object.keys(props.singletons).length.should.be.eq properties.length

      it 'singletons all savedDetails', ->
        mainPromise
        .then (props) ->
          Promise.all _.map props.singletons, (val) ->
            val.savedDetails.should.be.ok
            (val.savedDetails.isPinned || val.savedDetails.isFavorite).should.be.ok

      it 'encodeStub called', ->
        mainPromise
        .then () ->
          encodeStub.called.should.be.ok

      it 'scrubPermissions called', ->
        mainPromise
        .then () ->
          combinedMock.scrubPermissions.called.should.be.ok

      it 'getFilterSummaryAsQuery called', ->
        mainPromise
        .then () ->
          combinedMock.getFilterSummaryAsQuery.called.should.be.ok
