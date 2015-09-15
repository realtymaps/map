qs = require 'qs'
describe "rmapsFilterManager", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    inject ($rootScope, rmapsFilterManager) =>
      @$rootScope = $rootScope

      @subject = rmapsFilterManager

  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok


    describe 'getFilters', ->

      it 'no selectedFilters should be empty', ->
        expect(@subject.getFilters()).to.empty

      describe 'single filter', ->
        it 'forSale', ->
          @$rootScope.selectedFilters =
            forSale: true

          expect(@subject.getFilters()).to.equal '&status%5B0%5D=for%20sale'

        it 'pending', ->
          @$rootScope.selectedFilters =
            pending: true

          expect(@subject.getFilters()).to.equal '&status%5B0%5D=pending'

        it 'sold', ->
          @$rootScope.selectedFilters =
            sold: true

          expect(@subject.getFilters()).to.equal '&status%5B0%5D=recently%20sold'

        it 'notForSale', ->
          @$rootScope.selectedFilters =
            notForSale: true

          expect(@subject.getFilters()).to.equal '&status%5B0%5D=not%20for%20sale'

      describe 'multi filters', ->

        it 'forSale and notForSale', ->
          @$rootScope.selectedFilters =
            forSale: true
            notForSale: true

          expect(@subject.getFilters()).to.equal '&' + qs.stringify(status: ['for sale', 'not for sale'])


        it 'forSale, sold and notForSale', ->
          @$rootScope.selectedFilters =
            forSale: true
            sold: true
            notForSale: true

          expect(@subject.getFilters()).to.equal '&' + qs.stringify(status: ['for sale', 'recently sold', 'not for sale'])
