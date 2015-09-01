{DIGIMAPS} = require '../../../backend/config/config'
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.properties.filterSummary'
Promise = require 'bluebird'
gjv = require 'geojson-validation'
mocks =
  map:
    state: require('../fixtures/mapState')
    filter: require('../fixtures/mapFilterFilterSummary')()

describe 'service.properties.filterSummary', ->
  beforeEach ->
    @subject = svc

  # NOTE this is really an integration test
  # This is important as the database column naming is highly dependent!
  it 'geojsonPolys returns valid geojson', (done) ->
    @subject.getFilterSummary mocks.map.state, mocks.map.filter
    .then (data) ->
      gjv.valid(data).should.be.ok
      done()
