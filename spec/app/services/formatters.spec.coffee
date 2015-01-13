testScope = 'FormattersService'

describe testScope, ->
  beforeEach ->
    angular.mock.module 'app'.ourNs()
    angular.mock.module 'uiGmapgoogle-maps.mocks'
    angular.mock.module 'uiGmapgoogle-maps'

    angular.mock.inject ['GoogleApiMock', (GoogleApiMock) =>
      @apiMock = new GoogleApiMock()
      @apiMock.mockAPI()
      @apiMock.mockLatLng()
      @apiMock.mockMarker()
      @apiMock.mockEvent()
    ]

    inject ['$rootScope', testScope.ourNs(),
      ($rootScope, Formatters) =>
        @$rootScope = $rootScope
        @subject = Formatters
    ]

  it 'subject can be created', ->
    @subject.should.be.ok

  describe 'Common', ->
    beforeEach ->
      @tempSubject = @subject
      @subject = @subject.Common
    afterEach ->
      @subject = @tempSubject

    describe 'intervals', ->
      it 'days', ->
        test =
          days: 12
        @subject.getInterval(test).should.equal "#{@tempSubject.JSON.readable(test)}"

      it 'months, days', ->
        test =
          months: 2
          days: 12
        @subject.getInterval(test).should.equal "#{@tempSubject.JSON.readable(test)}"

      it 'years, months, days', ->
        test =
          years: 1
          months: 2
          days: 12
        @subject.getInterval(test).should.equal "#{@tempSubject.JSON.readable(test)}"
