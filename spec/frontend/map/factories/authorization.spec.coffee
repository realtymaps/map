_ = require 'lodash'
sinon = require 'sinon'

describe "rmapsMapAuthorizationFactory", ->
  $state = $rootScope = instance = instance2 = rmapsPriorStateService = null
  beforeEach ->

    angular.mock.module('rmapsMapApp')

    inject (_$state_, _$rootScope_, _rmapsMapAuthorizationFactory_, _digestor_, _rmapsPriorStateService_) ->
      $rootScope = _$rootScope_
      # digestor = _digestor_
      instance = _rmapsMapAuthorizationFactory_
      $state = _$state_
      rmapsPriorStateService = _rmapsPriorStateService_

    inject (_rmapsMapAuthorizationFactory_) ->
      instance2 = _rmapsMapAuthorizationFactory_


  it 'singleton exists', ->
    instance.should.be.ok

  it 'is singleton', ->
    instance.should.be.deep.equal(instance2)

  describe 'goToPostLoginState', ->
    describe 'No prior state', ->
      beforeEach ->
        rmapsPriorStateService.getPrior = sinon.stub().returns(null)

      it 'Subscriber goes to map', ->
        $state.go = sinon.stub().returns(true)

        $rootScope.principal =
          isSubscriber: sinon.stub().returns(true)
          isProjectViewer: sinon.stub().returns(false)

        instance.goToPostLoginState()
        $rootScope.principal.isSubscriber.called.should.be.ok
        $rootScope.principal.isProjectViewer.called.should.not.be.ok
        $state.go.called.should.be.ok
        $state.go.args[0][0].should.be.deep.equal 'map'

      it 'ProjectViewer goes to map', ->
        $state.go = sinon.stub().returns(true)
        $rootScope.principal =
          isSubscriber: sinon.stub().returns(false)
          isProjectViewer: sinon.stub().returns(true)

        instance.goToPostLoginState()
        $rootScope.principal.isSubscriber.called.should.be.ok
        $rootScope.principal.isProjectViewer.called.should.be.ok
        $state.go.called.should.be.ok
        $state.go.args[0][0].should.be.deep.equal 'map'

    describe 'With prior state', ->
      beforeEach ->
        rmapsPriorStateService.getPrior = sinon.stub().returns(state: 'test')

      it 'Subscriber goes to prior state', ->
        $state.go = sinon.stub().returns(true)

        $rootScope.principal =
          isSubscriber: sinon.stub().returns(true)
          isProjectViewer: sinon.stub().returns(false)

        instance.goToPostLoginState()
        $rootScope.principal.isSubscriber.called.should.be.ok
        $rootScope.principal.isProjectViewer.called.should.not.be.ok
        $state.go.called.should.be.ok
        $state.go.args[0][0].should.be.deep.equal 'test'

      it 'ProjectViewer goes to prior state', ->
        $state.go = sinon.stub().returns(true)
        $rootScope.principal =
          isSubscriber: sinon.stub().returns(false)
          isProjectViewer: sinon.stub().returns(true)

        instance.goToPostLoginState()
        $rootScope.principal.isSubscriber.called.should.be.ok
        $rootScope.principal.isProjectViewer.called.should.be.ok
        $state.go.called.should.be.ok
        $state.go.args[0][0].should.be.deep.equal 'test'

    it 'No subscriber or project viewer routes to userSubscription', ->
      $state.go = sinon.stub().returns(true)
      $rootScope.principal =
        isSubscriber: sinon.stub().returns(false)
        isProjectViewer: sinon.stub().returns(false)

      instance.goToPostLoginState()
      $rootScope.principal.isSubscriber.called.should.be.ok
      $rootScope.principal.isProjectViewer.called.should.be.ok
      $state.go.called.should.be.ok
      $state.go.args.should.be.deep.equal [['userSubscription']]
