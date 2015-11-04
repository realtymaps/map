_ = require 'lodash'

describe "common.service.rendering", ->
  beforeEach ->

    angular.mock.module 'rmapsCommon'
    inject ($rootScope, $timeout, rmapsRendering, digestor) =>
      @digestor = digestor
      @subject = rmapsRendering

  it 'exists', ->
    @subject.should.be.ok

  describe 'debounce', ->
    beforeEach ->
      @stateObj =
        tracker: false
      for x in [0..3]
        @ret = @subject.debounce @stateObj, 'tracker', (->)
        , 1000

    afterEach ->
      @ret = null
      @stateObj = null

    it 'returns a promise', ->
      _.isObject(@ret).should.be.ok
      _.isFunction(@ret.then).should.be.ok

    it 'stateObj property as promise persists', ->
      _.isObject(@stateObj.tracker).should.be.ok
      _.isFunction(@stateObj.tracker.then).should.be.ok

    it 'is reset upon digest and $timeouts cleared', ->
      @digestor.digest()
      _.isObject(@stateObj.tracker).should.not.be.ok
      @stateObj.tracker.should.not.be.ok
