###global angular:true, inject:true###
steps = ['onBoardingPayment', 'onBoardingVerify']

describe "rmapsOnBoardingProOrder", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    inject ($rootScope,  rmapsOnBoardingProOrder) =>
      @$rootScope = $rootScope
      @subject = rmapsOnBoardingProOrder

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
