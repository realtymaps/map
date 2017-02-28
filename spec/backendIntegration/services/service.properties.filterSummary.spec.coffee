require('chai').should()
rewire = require 'rewire'
svc = rewire '../../../backend/services/service.properties.filterSummary'
utilsGeoJson = require '../../../common/utils/util.geomToGeoJson'
gjv = require 'geojson-validation'
_ = require 'lodash'

mocks =
  map:
    state: require('../../fixtures/backend/mapState')
    filter: require('../../fixtures/backend/mapFilterFilterSummary')()

describe 'service.properties.filterSummary', ->

  xit 'clusterOrDefault returned works with geoJson', (done) ->
    svc.getFilterSummary
      profile: {
        auth_user_id: 1
        state: mocks.map.state
      },
      validBody: mocks.map.filter
    .then (data) ->
      properties = _.values(data.singletons)
      properties.length.should.be.above 0
      data = utilsGeoJson.toGeoFeatureCollection(rows: properties)
      gjv.valid(data).should.be.ok
      done()
