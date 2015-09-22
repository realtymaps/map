Point = require('../../../../common/utils/util.geometries.coffee').Point
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mockRoutes = require '../fixtures/propertyData.coffee'

describe "rmapsMap factory", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    @mocks =
      options:
        json:
          center: _.extend Point(latitude: 26.221501806466513, longitude: -81.80125951766968), zoom: mockRoutes.zoom

      zoomThresholdMilli: 1000

    inject ($rootScope, rmapsMap, rmapsMainOptions, $httpBackend, digestor, rmapsMapToggles) =>
      @$rootScope = $rootScope
      $rootScope.silenceRmapsControls = true
      @rmapsMapToggles = rmapsMapToggles
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

        it 'has mocked geojsonPolys response', (done) ->
          @subject.hash = mockRoutes.hash
          @subject.mapState = mockRoutes.mapState
          @subject.scope.Toggles = @rmapsMapToggles()
            # showResults: true
          promises = @subject.drawFilterSummary(true)
          @digestor.digest()
          console.log promises[0]
          promises[0].then ({data}) ->
            angular.equals(data,mockRoutes.geojsonPolys.response).should.equal true
            done()
          promises[0].catch ->
            should.fail()
          @digestor.digest()
