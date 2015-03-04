describe "ResultsFormatter", ->
  beforeEach ->
    @mapCtrl =
      scope:
        options:
          zoomThresh:
            addressParcel: 18

    angular.mock.module 'app'.ourNs()
    angular.mock.module "uiGmapgoogle-maps.mocks"
    angular.mock.module "uiGmapgoogle-maps"

    inject ['$rootScope', 'GoogleApiMock', 'ResultsFormatter'.ourNs(),
      ($rootScope, GoogleApiMock, ResultsFormatter) =>
        scope = $rootScope.$new()
        (new GoogleApiMock).initAll()
        @ctor = ResultsFormatter
        @mapCtrl.scope =_.extend scope, @mapCtrl.scope
        @subject = new ResultsFormatter(@mapCtrl)

    ]

  it 'ctor exists', ->
    @ctor.should.be.ok

  it 'subject can be created', ->
    @subject.should.be.ok

  describe 'zoomTo', ->
    it 'sets center and zoom level', ->
      @subject.zoomTo
        geom_point_json:
          type: 'Point'
          coordinates: [160, 70]

      expect(@mapCtrl.scope.zoom).to.eql @mapCtrl.scope.options.zoomThresh.addressParcel
      expect(@mapCtrl.scope.center).to.eql
        latitude: 70
        longitude: 160

    it 'zoom only', ->
      @subject.zoomTo
        geom_point_json:
          type: 'Point'
          coordinates: [160, 70]
      , false

      expect(@mapCtrl.scope.zoom).to.not.be.ok
      expect(@mapCtrl.scope.center).to.eql
        latitude: 70
        longitude: 160



