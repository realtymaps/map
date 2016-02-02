
describe 'NgLeafletEventGate', ->
  beforeEach ->
    angular.mock.module 'rmapsMapApp'
    inject ($rootScope, digestor, rmapsNgLeafletEventGateService) =>
      @$rootScope = $rootScope
      @digestor = digestor
      @subject = rmapsNgLeafletEventGateService

  it 'subject can be created', ->
    @subject.should.be.ok

  it 'disable event', ->
    @subject.disableEvent("mainMap", "click")
    @subject.getEvent("mainMap", "click").should.be.ok

  describe 'enable events', ->
    it 'never enabled', ->
      @subject.enableEvent("mainMap", "click")
      expect(@subject.getEvent("mainMap", "click")).to.not.be.ok

    it 'from disable', ->
      @subject.disableEvent("mainMap", "click")
      @subject.enableEvent("mainMap", "click")
      expect(@subject.getEvent("mainMap", "click")).to.not.be.ok
