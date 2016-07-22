qs = require 'qs'
backendRoutes = require '../../../../common/config/routes.backend.coffee'
sinon = require 'sinon'

describe "rmapsFilterManagerService", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    inject ($rootScope, rmapsFilterManagerService, rmapsEventConstants, digestor, $httpBackend) =>
      @$rootScope = $rootScope
      @rmapsEventConstants =  rmapsEventConstants
      @subject = rmapsFilterManagerService
      @digestor = digestor

      identity = {
        currentProfileId: 1,
        profiles: {
          1: {
            id: 1
          }
        }
      }

      $httpBackend.when( 'GET', backendRoutes.userSession.identity).respond( identity: identity )
      $httpBackend.when( 'POST', backendRoutes.userSession.currentProfile).respond( identity: identity )
      $httpBackend.when( 'GET', backendRoutes.properties.saves).respond( pins: {}, favorites: {})


  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok


    describe 'rmapsEventConstants.map.filters.updated', ->

      it 'is emited on update', (done) ->

        @$rootScope.selectedFilters = {}
        @digestor.digest()

        spyCb = sinon.spy @$rootScope, '$emit'
        @$rootScope.$on @rmapsEventConstants.map.filters.updated, (event, filters) =>
          expect(filters).to.eql {"hasImages":false,"soldRange":"120 day","discontinued":false,"auction":false,"status":[]}
          done()

        @$rootScope.selectedFilters =
          forSale: true

        @digestor.digest()
        @digestor.digest()

        spyCb.called.should.be.ok

    describe 'getFilters', ->

      it 'no selectedFilters should be empty', ->
        expect(@subject.getFilters()).to.empty

      describe 'single filter', ->
        it 'forSale', ->
          @$rootScope.selectedFilters =
            forSale: true

          expect(@subject.getFilters()).to.eql status: ['for sale']

        it 'pending', ->
          @$rootScope.selectedFilters =
            pending: true

          expect(@subject.getFilters()).to.eql status: ['pending']

        it 'sold', ->
          @$rootScope.selectedFilters =
            sold: true

          expect(@subject.getFilters()).to.eql status: ['sold']

      describe 'multi filters', ->

        it 'forSale and pending', ->
          @$rootScope.selectedFilters =
            forSale: true
            pending: true

          expect(@subject.getFilters()).to.eql status: ['for sale', 'pending']
