require('chai').should()
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.properties.filterSummary'
gjv = require 'geojson-validation'
mocks =
  map:
    state: require('../fixtures/mapState')
    filter: require('../fixtures/mapFilterFilterSummary')()

describe 'service.properties.filterSummary', ->

  if process.env.CIRCLECI
    it "can't run on CircleCI because postgres-based trigram matching can't be mocked", () ->
      #noop
    return
  beforeEach ->
    @subject = svc

  # NOTE this is really an integration test
  # This is important as the database column naming is highly dependent!
  it 'geojsonPolys returns valid geojson', (done) ->
    this.timeout(10000) # give it a longer timeout since 2s doesn't seem to be enough
    @subject.getFilterSummary mocks.map.state, mocks.map.filter
    .then (data) ->
      gjv.valid(data).should.be.ok
      done()
