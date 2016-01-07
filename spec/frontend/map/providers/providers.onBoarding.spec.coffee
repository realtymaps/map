###global angular:true, inject:true###
steps = ['onboardingPayment', 'onboardingVerify']

describe "rmapsOnboardingProOrder", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    inject ($rootScope,  rmapsOnboardingProOrder) =>
      @$rootScope = $rootScope
      @subject = rmapsOnboardingProOrder

  it 'subject exists', ->
    @subject.should.be.ok

  describe 'getStepName', ->
    steps.forEach (name, index) ->
      it index, ->
        @subject.getStepName(index).should.be.eql name + 'Pro'

  describe 'getId', ->
    steps.forEach (name, index) ->
      it name, ->
        @subject.getId(name).should.be.eql index
