rewire = require 'rewire'
svc = rewire '../../../backend/services/service.properties.parcels'
Promise = require 'bluebird'
gjv = require 'geojson-validation'
require("chai").should()

mocks =
  map:
    state: require('../../fixtures/backend/mapState')
    filter: require('../../fixtures/backend/mapFilter')

describe 'service.properties.parcels', ->

  beforeEach ->
    @subject = svc

  # NOTE this is really an integration test
  # This is important as the database column naming is highly dependent!
  it 'getBaseParcelData returns valid geojson', (done) ->
    @subject.getBaseParcelData mocks.map.state, mocks.map.filter
    .then (data) ->
      gjv.valid(data).should.be.ok
      done()
