priceMarkerTemplate = require '../../../../frontend/map/html/includes/map/markers/_priceMarker\.jade'

describe "rmapsLayerFormattersService", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    inject ($rootScope,  rmapsLayerFormattersService, rmapsStylusConstants) =>
      @$rootScope = $rootScope
      @subject = rmapsLayerFormattersService
      @rmapsStylusConstants = rmapsStylusConstants


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
                    isPinned: true
                3:
                  savedDetails:
                    isPinned: false
                5:
                  savedDetails:
                    isPinned: undefined
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

            it 'savedDetails isPinned undefined', ->
              @subject.isVisible(@mockScope, {rm_property_id:4, savedDetails:{isPinned:undefined}}).should.be.not.ok

            it 'savedDetails isPinned false', ->
              @subject.isVisible(@mockScope, {rm_property_id:4, savedDetails:{isPinned:false}}).should.be.not.ok

        describe 'in filterSummary', ->
          it 'savedDetails isPinned false', ->
            @subject.isVisible(@mockScope, rm_property_id:1).should.be.not.ok

          it 'savedDetails isPinned undefined', ->
            @subject.isVisible(@mockScope, rm_property_id:5).should.be.not.ok

          it 'savedDetails isPinned false', ->
            @subject.isVisible(@mockScope, rm_property_id:3).should.be.not.ok

      describe 'true', ->
        describe 'not in filterSummary', ->
          it 'model requireFilterModel true', ->
            @subject.isVisible(@mockScope, {rm_property_id:2}, true).should.be.ok

        describe 'in filterSummary', ->
          it 'savedDetails isPinned', ->
            @subject.isVisible(@mockScope, {rm_property_id:4, savedDetails:{isPinned:true}}).should.be.ok

    describe 'MLS', ->

      before ->
        @subject = @subject.MLS

      describe 'setMarkerPriceOptions extends the model', ->

        describe 'price', ->

          it 'none', ->
            model = @testObj = @subject.setMarkerPriceOptions {status: 'sold'}
            expect(model.markerType).to.be.equal 'price'
            expect(model.icon.type).to.be.equal 'div'
            expect(model.icon.iconSize).to.include.members [60, 30]
            expect(model.icon.html).to.be.equal priceMarkerTemplate(price:'-', priceClasses: "label-sold-property")

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

    describe 'Parcels', ->
      weight = 4
      colorOpacity = 1
      fillOpacity = .75

      describe 'getStyle', ->
        before ->
          @subject = @subject.Parcels.getStyle

        describe 'w/o layerName', ->
          it 'undefined feature', ->
            (@subject undefined).should.be.ok

          it 'feature saved', ->
            style = @subject {savedDetails:isPinned: true}
            style.should.be.ok
            style.weight.should.be.equal weight
            style.color.should.not.be.equal @rmapsStylusConstants['$rm_saved']
            style.fillColor.should.be.equal @rmapsStylusConstants['$rm_saved']
            style.fillOpacity.should.be.equal fillOpacity
            style.colorOpacity.should.be.equal colorOpacity

          describe 'feature not saved', ->
            it 'w no status', ->
              style = @subject {savedDetails:isPinned: false}
              style.should.be.ok
              style.weight.should.be.equal weight
              style.color.should.be.equal 'transparent'
              style.fillColor.should.be.equal 'transparent'
              style.fillOpacity.should.be.equal fillOpacity
              style.colorOpacity.should.be.equal colorOpacity

            it 'invalid status', ->
              style = @subject(
                status: 'crap'
                savedDetails:
                  isPinned: false
              )

              style.should.be.ok
              style.weight.should.be.equal weight
              style.color.should.be.equal 'transparent'
              style.fillColor.should.be.equal 'transparent'
              style.fillOpacity.should.be.equal fillOpacity

            it 'sold', ->
              style = @subject(
                status: 'sold'
                savedDetails:
                  isPinned: false
              )

              style.should.be.ok
              style.weight.should.be.equal weight
              style.color.should.be.equal @rmapsStylusConstants.$rm_sold
              style.fillColor.should.be.equal @rmapsStylusConstants.$rm_sold
              style.fillOpacity.should.be.equal fillOpacity

        describe 'w/ layerName', ->
