require('chai').should()
svc = require '../../../backend/services/service.properties.combined.filterSummary'


describe 'service.properties.filterSummary', ->

  it 'should skip query when no status, pins, or favorites', () ->
    query = svc.getFilterSummaryAsQuery(queryParams: {})
    query.toString().should.equal('NOTHING TO QUERY!')
