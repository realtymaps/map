Point = require('../../../../common/utils/util.geometries.coffee').Point
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mockRoutes = require '../fixtures/propertyData.coffee'

describe "rmapsMap factory", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    @mocks =
      options:
        json:
          center: _.extend Point(latitude: 26.221501806466513, longitude: -81.80125951766968), zoom: 3

      zoomThresholdMilli: 1000

    inject ($rootScope, rmapsMap, rmapsMainOptions, $httpBackend, digestor) =>
      @$rootScope = $rootScope
      $rootScope.silenceRmapsControls = true
      @digestor = digestor
      @ctor = rmapsMap
      @subject = new rmapsMap($rootScope.$new(), rmapsMainOptions.map)

      $httpBackend.when( 'GET', backendRoutes.userSession.identity).respond( identity: {})
      $httpBackend.when( 'GET', mockRoutes.geojsonPolys.route).respond( mockRoutes.geojsonPolys.response)
      $httpBackend.when( 'GET', mockRoutes.clusterOrDefault.route).respond( mockRoutes.clusterOrDefault.response)


  it 'ctor exists', ->
    @ctor.should.be.ok

  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok

    describe 'drawFilterSummary', ->
      it 'can run', ->
        @subject.drawFilterSummary(false)

      it 'has zero promises, with no filter', ->
        promises = @subject.drawFilterSummary(false)
        promises.should.be.ok
        promises.length.should.be.equal 0

      describe 'with filters', ->
        beforeEach ->
          @$rootScope.selectedFilters =
            forSale: true
            sold: true
            pending: true

        it 'has 1 promise', ->
          promises = @subject.drawFilterSummary(false)
          promises.should.be.ok
          promises.length.should.be.equal 1

        xit 'has mocked cluserOrDefault response', (done) ->
          promises = @subject.drawFilterSummary(false)
          @subject.hash = mockRoutes.hash
          promises[0].then (data) ->
            data.should.be.equal mockRoutes.clusterOrDefault.response
            done()
          @digestor.digest()
