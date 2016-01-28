###global inject:true, angular:true,expect:true###
# sinon = require 'sinon'

describe "rmapsOnboardingOrder", ->
  beforeEach ->

    angular.mock.module 'rmapsMapApp'

    inject ($rootScope, rmapsOnboardingOrder) =>
      @$rootScope = $rootScope
      @subject = rmapsOnboardingOrder

  describe 'subject', ->

    it 'can be created', ->
      @subject.should.be.ok

    it 'clazz exists', ->
      @subject.clazz.should.be.ok
      @subject.clazz.should.be.a 'function'

    describe 'inBounds', ->
      it 'function', ->
        @subject.inBounds.should.be.a 'function'

      it 'is inbounds', ->
        @subject.inBounds(2).should.be.true

      it 'not inbounds', ->
        @subject.inBounds(3).should.be.false

    describe 'getStep', ->
      [ 'onboardingPayment', 'onboardingLocation','onboardingFinishYay'].forEach (name, index) ->
        it index, ->
          @subject.getStep(index).should.be.eql name

      it 'bad step index is undefined', ->
        expect(@subject.getStep(4)).to.not.be.ok

    describe 'getStepName', ->
      afterEach ->
        @subject.name = ''

      [ 'onboardingPayment', 'onboardingLocation','onboardingFinishYay'].forEach (name, index) ->
        it index, ->
          @subject.getStepName(index).should.be.eql name

      [ 'onboardingPayment', 'onboardingLocation','onboardingFinishYay'].forEach (name, index) ->
        it index.toString() + ' w/ a name', ->
          @subject.name = 'crap'
          @subject.getStepName(index).should.be.eql name + 'Crap'

    describe 'getId', ->
      [ 'onboardingPayment', 'onboardingLocation','onboardingFinishYay'].forEach (name, index) ->
        it name, ->
          @subject.getId(name).should.be.eql index

      it 'bad name', ->
        expect(@subject.getStep()).to.not.be.ok

    describe 'getNextStep', ->
      array = [ 'onboardingPayment', 'onboardingLocation','onboardingFinishYay']
      array.forEach (name, index) ->
        it name, ->
          nextStep = if index < array.length then array[index + 1] else undefined
          expect(@subject.getNextStep(name)).to.be.eql nextStep

      it 'non existant name', ->
        expect(@subject.getNextStep('junk')).to.not.be.ok

    describe 'getPrevStep', ->
      array = [ 'onboardingPayment', 'onboardingLocation','onboardingFinishYay']
      array.forEach (name, index) ->
        it name, ->
          step = if !index then undefined else array[index - 1]
          expect(@subject.getPrevStep(name)).to.be.eql step

      it 'non existant name', ->
        expect(@subject.getPrevStep('junk')).to.not.be.ok
