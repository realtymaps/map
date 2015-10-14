describe "common qDecorator", ->
  beforeEach ->

    angular.mock.module 'rmapsCommon'
    inject ($rootScope, digestor, $q) =>
      @digestor = digestor
      @subject = $q

  it 'exists', ->
    @subject.should.be.ok

  ['resolve', 'reject'].forEach (testName) ->
    describe testName, ->

      it 'exists', ->
        @subject[testName].should.be.ok

      it 'executes correctly', ->
        test = 'thing'
        @subject[testName](test).then (ret) ->
          ret.should.be.equal test
        @digestor.digest()
