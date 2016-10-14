testScope = 'rmapsFormattersService'

describe testScope, ->
  beforeEach ->
    angular.mock.module 'rmapsMapApp'

    inject ['$rootScope', testScope,
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
      it '2 units result', ->
        @subject.humanizeDays(600).should.equal "about 1 year, 8 months"
        @subject.humanizeDays(62).should.equal "2 months, 1 day"
        @subject.humanizeDays(60).should.equal "1 month, 29 days"
        @subject.humanizeDays(337).should.equal "11 months, 2 days"
        @subject.humanizeDays(720).should.equal "about 2 years"
        @subject.humanizeDays(705).should.equal "about 1 year, 11 months"
        @subject.humanizeDays(0).should.equal "less than 1 day"
      it '1 unit result', ->
        @subject.humanizeDays(732).should.equal "about 2 years"
