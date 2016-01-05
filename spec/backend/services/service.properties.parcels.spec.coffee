rewire = require 'rewire'
svc = rewire '../../../backend/services/service.properties.parcels'
Promise = require 'bluebird'
gjv = require 'geojson-validation'
mocks =
  map:
    state: require('../fixtures/mapState')
    filter: require('../fixtures/mapFilter')

describe 'service.properties.parcels', ->
  if process.env.CIRCLECI
    it "can't run on CircleCI because it's an integration test that hits the db", () ->
      #noop
    return

  beforeEach ->
    @subject = svc

  # NOTE this is really an integration test
  # This is important as the database column naming is highly dependent!
  it 'getBaseParcelData returns valid geojson', (done) ->
    @subject.getBaseParcelData mocks.map.state, mocks.map.filter
    .then (data) ->
      gjv.valid(data).should.be.ok
      done()
