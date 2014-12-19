describe 'Promise', ->
  beforeEach ->
    #console.info 'beforeEach ->'

    _$rootScope = undefined
    @digest = (fn) ->
      fn()
      _$rootScope.$apply()
    angular.mock.module 'app'.ourNs()
    angular.mock.inject ($rootScope, $q) =>
      _$rootScope = $rootScope
      @q = $q
      d = $q.defer()
      d.resolve()
      @Promise = d.promise
      @ctr = 0

      @expectCounter = (expectedCount, done) =>
        @ctr += 1
        done() if expectedCount == @ctr

  it 'promise can resolve multiple times', (done)->
    @digest =>
      @Promise.then =>
        @expectCounter(3, done)
      @Promise.then =>
        @expectCounter(3, done)
      @Promise.then =>
        @expectCounter(3, done)