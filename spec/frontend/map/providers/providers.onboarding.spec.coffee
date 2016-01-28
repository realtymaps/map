###global inject:true, angular:true ###
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
