Point = require('../../../../common/utils/util.geometries.coffee').Point

describe "rmapsLayerFormatters", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    @mocks =
      options:
        json:
          center: _.extend Point(latitude: 90.0, longitude: 89.0), zoom: 3

      zoomThresholdMilli: 1000

    inject ($rootScope,  rmapsLayerFormatters) =>
      @$rootScope = $rootScope
      @subject = rmapsLayerFormatters


  it 'subject exists', ->
    @subject.should.be.ok

  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok

    describe 'isVisible', ->
      beforeEach ->
        @mockScope =
          map:
            markers:
              filterSummary:{
                1:
                  savedDetails:{}
                2:
                  savedDetails:
                    isSaved: true
                3:
                  savedDetails:
                    isSaved: false
                5:
                  savedDetails:
                    isSaved: undefined
              }


      describe 'false', ->
        it 'no model', ->
          @subject.isVisible(@mockScope, null).should.be.not.ok

        it 'model requireFilterModel true', ->
          @subject.isVisible(@mockScope, {}, true).should.be.not.ok

        it 'model requireFilterModel true, not in filterSummary', ->
          @subject.isVisible(@mockScope, {rm_property_id:4}, true).should.be.not.ok

        describe 'not in filterSummary', ->
          describe 'no passedFilters', ->
            it 'savedDetails is undefined', ->
              @subject.isVisible(@mockScope, {rm_property_id:4}).should.be.not.ok

            it 'savedDetails isSaved undefined', ->
              @subject.isVisible(@mockScope, {rm_property_id:4, savedDetails:{isSaved:undefined}}).should.be.not.ok

            it 'savedDetails isSaved false', ->
              @subject.isVisible(@mockScope, {rm_property_id:4, savedDetails:{isSaved:false}}).should.be.not.ok

        describe 'in filterSummary', ->
          it 'savedDetails isSaved false', ->
            @subject.isVisible(@mockScope, rm_property_id:1).should.be.not.ok

          it 'savedDetails isSaved undefined', ->
            @subject.isVisible(@mockScope, rm_property_id:5).should.be.not.ok

          it 'savedDetails isSaved false', ->
            @subject.isVisible(@mockScope, rm_property_id:3).should.be.not.ok

      describe 'true', ->
        describe 'not in filterSummary', ->
          it 'model requireFilterModel true', ->
            @subject.isVisible(@mockScope, {rm_property_id:2}, true).should.be.ok

        describe 'in filterSummary', ->
          it 'savedDetails isSaved', ->
            @subject.isVisible(@mockScope, {rm_property_id:4, savedDetails:{isSaved:true}}).should.be.ok

    describe 'MLS', ->

      before ->
        @subject = @subject.MLS

      describe 'setMarkerPriceOptions extends the model', ->

        describe 'price', ->

          it 'none', ->
            model = @testObj = @subject.setMarkerPriceOptions {}
            status = 'undefined'
            hovered = ''
            formattedPrice = ' &nbsp; &nbsp; &nbsp;'

            expect(model.markerType).to.be.equal 'price'
            expect(model.icon.type).to.be.equal 'div'
            expect(model.icon.iconSize).to.include.members [60, 30]
            expect(model.icon.html).to.be.equal "<h4><span class='label label-#{status}#{hovered}'>#{formattedPrice}</span></h4>"

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
