### globals _, angular, inject###
Point = require('../../../../common/utils/util.geometries.coffee').Point

describe "BaseMapCtrl", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    @mocks =
      options:
        json:
          center: _.extend Point(latitude: 90.0, longitude: 89.0), zoom: 3

      zoomThresholdMilli: 1000

    inject ($rootScope, rmapsBaseMapFactory) =>
      @$rootScope = $rootScope

      @ctor = rmapsBaseMapFactory
      @subject = new rmapsBaseMapFactory {
        scope: $rootScope.$new()
        options: @mocks.options
        redrawDebounceMilliSeconds: @mocks.zoomThresholdMilli
      }

  it 'ctor exists', ->
    @ctor.should.be.ok

  it 'subject can be created', ->
    @subject.should.be.ok
