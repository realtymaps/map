###globals angular,inject###
L = require 'leaflet'
describe 'services.drawn.coffee', ->

  describe "rmapsDrawnProfileFactory", ->
    beforeEach ->

      angular.mock.module 'rmapsMapApp'

      inject ($rootScope,  rmapsDrawnProfileFactory) =>
        @$rootScope = $rootScope
        @subject = rmapsDrawnProfileFactory(project_id:1)

    it 'exists', ->
      @subject.should.be.ok

    describe 'normalize geojson', ->
      it 'exists', ->
        @subject.normalize.should.be.ok

      it 'circle', ->
        geojson = L.circle([50.5, 30.5], 200).toGeoJSON()
        geojson.properties.area_name = 'crap'
        geojson.properties.id = 1
        geojson.properties.area_details = 'details'


        result = @subject.normalize geojson
        #validate db object
        result.area_name.should.be.eql 'crap'
        result.shape_extras.type.should.be.eql 'Circle'
        result.shape_extras.radius.should.be.equal 200
        result.area_details.should.be.equal 'details'
        result.id.should.be.equal 1
