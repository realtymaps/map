require('chai').should()
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.properties.filterSummary'
utilsGeoJson = require '../../../common/utils/util.geomToGeoJson'
gjv = require 'geojson-validation'
logger = require('../../specUtils/logger').spawn('integration:filterSummary')
_ = require 'lodash'

mocks =
  map:
    state: require('../../fixtures/backend/mapState')
    filter: require('../../fixtures/backend/mapFilterFilterSummary')()

describe 'service.properties.filterSummary', ->

  beforeEach ->
    @subject = svc

  xit 'clusterOrDefault returned works with geoJson', (done) ->
    @subject.getFilterSummary
      profile: {
        auth_user_id: 1
        state: mocks.map.state
      },
      limit: 1
      validBody: mocks.map.filter
    .then (data) ->
      properties = _.values(data.singletons)
      properties.length.should.be.above 0
      data = utilsGeoJson.toGeoFeatureCollection(properties)
      gjv.valid(data).should.be.ok
      done()
