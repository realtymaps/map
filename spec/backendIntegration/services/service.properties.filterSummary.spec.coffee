require('chai').should()
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.properties.filterSummary'
utilsGeoJson = require '../../../common/utils/util.geomToGeoJson'
gjv = require 'geojson-validation'

mocks =
  map:
    state: require('../../fixtures/backend/mapState')
    filter: require('../../fixtures/backend/mapFilterFilterSummary')()

describe 'service.properties.filterSummary', ->

  beforeEach ->
    @subject = svc

  it 'clusterOrDefault returned works with geoJson', (done) ->
    @subject.getFilterSummary { state: mocks.map.state, req: mocks.map.filter }
    .then (data) ->
      data = utilsGeoJson.filterSummaryToGeoFeatureCollection(data)
      gjv.valid(data).should.be.ok
      done()
