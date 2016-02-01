priceMarkerTemplate = require '../../../../frontend/map/html/includes/map/_priceMarker.jade'

describe "rmapsLayerFormattersService", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    inject ($rootScope,  rmapsLayerFormattersService, rmapsstylusVariables) =>
      @$rootScope = $rootScope
      @subject = rmapsLayerFormattersService
      @rmapsstylusVariables = rmapsstylusVariables


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
            formattedPrice = '-'

            expect(model.markerType).to.be.equal 'price'
            expect(model.icon.type).to.be.equal 'div'
            expect(model.icon.iconSize).to.include.members [60, 30]
            expect(model.icon.html).to.be.equal priceMarkerTemplate(price:formattedPrice, priceClasses: "label-#{status}#{hovered}")

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

      describe 'labelFromStreetNum', ->
        before ->
          @subject = @subject.Parcels.labelFromStreetNum

        it 'model with nothin', ->
          model = @subject {}
          model.markerType.should.be.equal 'streetNum'
          model.zIndex.should.be.equal 1
          expect(model.icon.iconSize).to.include.members [10, 10]
          expect(model.icon.html).to.be.equal "<span class='address-label'>#{String.orNA undefined}</span>"

        it 'model with streetNum', ->
          model = @subject street_address_num: 12
          model.markerType.should.be.equal 'streetNum'
          model.zIndex.should.be.equal 1
          expect(model.icon.iconSize).to.include.members [10, 10]
          expect(model.icon.html).to.be.equal "<span class='address-label'>12</span>"

      describe 'getStyle', ->
        before ->
          @subject = @subject.Parcels.getStyle

        describe 'w/o layerName', ->
          it 'undefined feature', ->
            (@subject undefined).should.be.ok

          it 'feature saved', ->
            style = @subject {savedDetails:isSaved: true}
            style.should.be.ok
            style.weight.should.be.equal 2
            style.color.should.be.equal @rmapsstylusVariables['$rm_saved']
            style.fillColor.should.be.equal @rmapsstylusVariables['$rm_saved']
            style.fillOpacity.should.be.equal .75

          describe 'feature not saved', ->
            it 'w no status', ->
              style = @subject {savedDetails:isSaved: false}
              style.should.be.ok
              style.weight.should.be.equal 2
              style.color.should.be.equal 'transparent'
              style.fillColor.should.be.equal 'transparent'
              style.fillOpacity.should.be.equal .75

            it 'invalid status', ->
              style = @subject(
                rm_status: 'crap'
                savedDetails:
                  isSaved: false
              )

              style.should.be.ok
              style.weight.should.be.equal 2
              style.color.should.be.equal 'transparent'
              style.fillColor.should.be.equal 'transparent'
              style.fillOpacity.should.be.equal .75

            it 'sold', ->
              style = @subject(
                rm_status: 'recently sold'
                savedDetails:
                  isSaved: false
              )

              style.should.be.ok
              style.weight.should.be.equal 2
              style.color.should.be.equal @rmapsstylusVariables.$rm_sold
              style.fillColor.should.be.equal @rmapsstylusVariables.$rm_sold
              style.fillOpacity.should.be.equal .75

        describe 'w/ layerName', ->
