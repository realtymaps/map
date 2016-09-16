{should} = require("chai")
should()
filterSummarImp = require '../../../backend/services/service.properties.combined.filterSummary'

describe "service.properties.combined.filterSummary", ->
  it 'exists', ->
    filterSummarImp.should.be.ok

  describe 'cluster', ->
    it 'exists', ->
      filterSummarImp.cluster.should.be.ok
