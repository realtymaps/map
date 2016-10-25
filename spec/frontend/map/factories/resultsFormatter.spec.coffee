describe "ResultsFormatter", ->
  beforeEach ->
    @mapCtrl =
      scope:
        options:
          zoomThresh:
            addressParcel: 18

    angular.mock.module 'rmapsMapApp'

    inject ['$rootScope', 'rmapsResultsFormatterService',
      ($rootScope, ResultsFormatter) =>
        scope = $rootScope.$new()
        @ctor = ResultsFormatter
        @mapCtrl.scope =_.extend scope, @mapCtrl.scope
        @subject = new ResultsFormatter(@mapCtrl)

    ]

  it 'ctor exists', ->
    @ctor.should.be.ok

  it 'subject can be created', ->
    @subject.should.be.ok

#  describe 'zoomTo', ->
#    it 'sets center and zoom level', ->
#      @subject.zoomTo(coordinates: [160, 70])
#
#      expect(@mapCtrl.scope.map.center.zoom).to.eql @mapCtrl.scope.options.zoomThresh.addressParcel
#      expect(@mapCtrl.scope.map.center).to.eql
#        lat: 70
#        lng: 160
#        zoom: @mapCtrl.scope.options.zoomThresh.addressParcel
#
#    it 'zoom only', ->
#      @subject.zoomTo(coordinates: [160, 70],false)
#
#      expect(@mapCtrl.scope.zoom).to.not.be.ok
#      expect(@mapCtrl.scope.center).to.eql
#        lat: 70
#        lng: 160
#        zoom: @mapCtrl.scope.options.zoomThresh.addressParcel



