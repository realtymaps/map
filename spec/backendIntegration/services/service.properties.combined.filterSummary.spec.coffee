require('chai').should()
svc = require '../../../backend/services/service.properties.combined.filterSummary'
logger = require('../../specUtils/logger').spawn('integration:filterSummary:combined')
_ = require 'lodash'


describe 'service.properties.filterSummary', ->

  it 'should skip query when no status, pins, or favorites', () ->
    query = svc.getFilterSummaryAsQuery(queryParams: {})
    query.toString().should.equal('NOTHING TO QUERY!')
