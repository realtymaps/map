Point = require('../../../../common/utils/util.geometries.coffee').Point

describe "rmapsMap factory", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    @mocks =
      options:
        json:
          center: _.extend Point(latitude: 90.0, longitude: 89.0), zoom: 3

      zoomThresholdMilli: 1000

    inject ($rootScope, rmapsMap, rmapsMainOptions) =>
      @$rootScope = $rootScope

      @ctor = rmapsMap
      @subject = new rmapsMap($rootScope.$new(), rmapsMainOptions.map)

  it 'ctor exists', ->
    @ctor.should.be.ok

  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok

    describe 'results handles', ->
