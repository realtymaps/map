{Point, NgLeafletCenter} = require('../../../../common/utils/util.geometries.coffee')
backendRoutes = require '../../../../common/config/routes.backend.coffee'

mockRoutes = require '../fixtures/propertyData.coffee'
qs = require 'qs'

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

    describe 'getMapStateObj', ->
      it 'can run', ->
        test = @subject.getMapStateObj()
        test.should.be.ok

      describe 'uses long position naming as pref', ->
        beforeEach ->
          @subject.scope.map =
            center:
              latitude: 89
              longitude: 178
          @subject.scope.zoom = mockRoutes.zoom

        it 'default (no results)', ->
          test = @subject.getMapStateObj()
          test.map_position.center.should.be.ok
          test.map_position.center.latitude.should.be.equal @subject.scope.map.center.latitude
          test.map_position.center.longitude.should.be.equal @subject.scope.map.center.longitude

          test.map_position.zoom.should.be.equal mockRoutes.zoom
          expect(test.map_results).to.not.be.ok

        it 'has invalid results', ->
          @subject.scope.selectedResult = {}
          test = @subject.getMapStateObj()
          expect(test.map_results).to.not.be.ok

        it 'has results', ->
          @subject.scope.selectedResult =
            rm_property_id: 1
          test = @subject.getMapStateObj()
          test.map_results.should.be.ok
          test.map_results.selectedResultId.should.be.equal 1

    describe 'refreshState', ->
      beforeEach ->
        @subject.getMapStateObj = ->
          a: 'a'

      it 'no args', ->
        test = @subject.refreshState()
        test.should.be.equal qs.stringify @subject.getMapStateObj()

      it 'args', ->
        arg = b: 'b'
        test = @subject.refreshState(arg)
        test.should.be.equal qs.stringify(angular.extend @subject.getMapStateObj(), arg )

    describe 'draw', ->
      beforeEach ->
        @subject.hash = mockRoutes.hash
        @subject.mapState = mockRoutes.mapState
        @subject.scope.Toggles = @rmapsMapToggles()

      afterEach ->
        @subject.map = null

      describe 'can run', ->
        it 'bails early identical lat bounds', ->
          @subject.map =
            getBounds: ->
              _northEast:
                lat: 90
                lng: 1
              _southWest:
                lat: 90
                lng: 1

          expect(@subject.draw()).to.not.be.ok

        it 'bails early identical lat/lng (invalid lon) bounds', ->
          @subject.map =
            getBounds: ->
              _northEast:
                lat: 90
                lon: 1
              _southWest:
                lat: 90
                lon: 1

          expect(@subject.draw()).to.not.be.ok

        it 'returns promises', ->
          #if this is not mocked it hangs draw
          @subject.refreshState = ->
            mockRoutes.mapState

          @subject.map =
            getBounds: ->
              _northEast:
                lat: 90
                lng: 1
              _southWest:
                lat: 35
                lng: 70

          expect(@subject.draw()).to.be.ok
