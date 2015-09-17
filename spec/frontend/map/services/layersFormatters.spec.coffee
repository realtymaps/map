Point = require('../../../../common/utils/util.geometries.coffee').Point

describe "rmapsLayerFormatters", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    @mocks =
      options:
        json:
          center: _.extend Point(latitude: 90.0, longitude: 89.0), zoom: 3

      zoomThresholdMilli: 1000

    inject ($rootScope, rmapsMap, rmapsMainOptions, rmapsLayerFormatters) =>
      @$rootScope = $rootScope

      @ctor = rmapsLayerFormatters

      ###
      TODO goal: remove the map as a dependency
      ###
      @subject = (new rmapsMap($rootScope.$new(), rmapsMainOptions.map)).layerFormatter

  it 'ctor exists', ->
    @ctor.should.be.ok

  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok

    describe 'MLS', ->

      before ->
        @subject = @subject.MLS

      describe 'setMarkerManualClusterOptions extends the model', ->
        beforeEach ->
          @testObj = @subject.setMarkerManualClusterOptions {}

        it 'has markerType', ->
          @testObj.markerType.should.be.equal 'cluster'

        it 'has icon', ->
          obj = @testObj.icon
          expect(obj).to.be.ok
          expect(obj.type).to.be.equal 'div'
          expect(obj.html).to.an 'string'
