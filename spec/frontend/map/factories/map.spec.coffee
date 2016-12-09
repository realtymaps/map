###globals angular, inject, should###
_ = require 'lodash'
{Point} = require('../../../../common/utils/util.geometries.coffee')
backendRoutes = require '../../../../common/config/routes.backend.coffee'
mockRoutes = require '../fixtures/propertyData.coffee'

describe "rmapsMapFactory factory", ->
  beforeEach ->

    angular.mock.module('rmapsMapApp')

    @mocks =
      options:
        json:
          center: _.extend Point(latitude: 26.221501806466513, longitude: -81.80125951766968), zoom: mockRoutes.zoom

    @mockMapData =
      whenReady: () ->
      invalidateSize: () ->
      getBounds: () ->
        intersects: () ->
          return false

      zoomThresholdMilli: 1000

    inject ($rootScope, rmapsMapFactory, rmapsMainOptions, $httpBackend, digestor, rmapsMapTogglesFactory) =>
      # Store variables for tests
      @$rootScope = $rootScope
      @rmapsMapTogglesFactory = rmapsMapTogglesFactory
      @digestor = digestor
      @ctor = rmapsMapFactory

      # Construct the rmapsMapFactory object to test
      @subject = new rmapsMapFactory($rootScope.$new(), rmapsMainOptions.map)

      identity = {
        currentProfileId: 1,
        profiles: {
          1: {
            id: 1
            project_id: 2
          }
        }
        user:{}
        permissions:{}
      }

      $httpBackend.when( 'GET', backendRoutes.userSession.identity).respond( identity: identity )
      $httpBackend.when( 'POST', backendRoutes.userSession.currentProfile).respond( identity: identity )
      $httpBackend.when( 'GET', backendRoutes.getProperties).respond([])

      $httpBackend.when( 'POST', mockRoutes.filterSummary.route).respond((method, url, dataString, headers, params) ->
        data = JSON.parse dataString

        if data.returnType == 'clusterOrDefault'
          return ['200', mockRoutes.filterSummary.clusterOrDefault]
        else
          return ['200', mockRoutes.filterSummary.geojsonPolys]
      )

  it 'ctor exists', ->
    @ctor.should.be.ok

  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok

    describe 'drawFilterSummary', ->
      it 'can run', ->
        @subject.drawFilterSummary({cache: false})
        return

      it 'returns a promise', ->
        promise = @subject.drawFilterSummary({cache: false})
        promise.should.be.ok
        promise.then.should.be.ok

      describe 'with filters', ->
        beforeEach ->
          @$rootScope.selectedFilters =
            forSale: true
            sold: true
            pending: true


        it 'has mocked clusterOrDefault response', ->
          @subject.hash = mockRoutes.hash
          @subject.mapState = mockRoutes.mapState
          @subject.map = @mockMapData
          @subject.scope.Toggles = new @rmapsMapTogglesFactory()

          # showResults: true
          promise = @subject.drawFilterSummary({cache: true})
          @digestor.digest()

          promise.catch ->
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
        test = @subject.scope.refreshState()
        test.should.be.eql @subject.getMapStateObj()

      it 'args', ->
        arg = b: 'b'
        test = @subject.scope.refreshState(arg)
        test.should.be.eql angular.extend(@subject.getMapStateObj(), arg)

    describe 'draw', ->
      beforeEach ->
        @subject.hash = mockRoutes.hash
        @subject.mapState = mockRoutes.mapState
        @subject.scope.Toggles = @rmapsMapTogglesFactory()

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
          drawn = @subject.draw()
          # console.log 'drawn'
          # console.log drawn
          expect(drawn).to.not.be.ok

        it 'returns promises', ->
          #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          #if this is not mocked it hangs draw
          #!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
          @subject.scope.refreshState = ->
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
