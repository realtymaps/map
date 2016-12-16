$timeout = $q = digestor = null

#direct port from bluebird.each specs
promised = (val, mill = 1)  ->
  # using $timeout for delay as specs hate setTimeout in angular
  # underlying code for delay is setTimeout due to circular dependency on $timeout to $q
  $q (resolve) ->
    $timeout ->
      resolve(val)
    , mill

thenabled = (val, arr) ->
  then: (f) ->
    $timeout ->
      if (arr)
        arr.push(val)
      f(val)
    , 1

describe "common qDecorator", ->
  beforeEach ->

    angular.mock.module 'rmapsCommon'
    inject (_digestor_, _$q_, _$timeout_) ->
      $q = _$q_
      digestor = _digestor_
      $timeout = _$timeout_

  it 'exists', ->
    $q.should.be.ok

  describe 'resolve', ->

    it 'exists', ->
      $q.resolve.should.be.ok

    it 'executes correctly', (done) ->
      test = 'thing'
      $q.resolve(test).then (ret) ->
        ret.should.be.equal test
        done()
      digestor.digest()

    it 'via resolver', (done) ->
      test = 'thing'
      $q (resolve, reject) ->
        resolve(test)
      .then (ret) ->
        ret.should.be.equal test
        done()
      digestor.digest()

  describe 'reject', ->

    it 'exists', ->
      $q.reject.should.be.ok

    it 'executes correctly', (done) ->
      test = 'thing'
      $q.reject(test).catch (ret) ->
        ret.should.be.equal test
        done()
      digestor.digest()

    it 'via resolver', (done) ->
      test = 'thing'
      $q (resolve, reject) ->
        reject(test)
      .catch (ret) ->
        ret.should.be.equal test
        done()
      digestor.digest()


  describe 'each', ->
    it 'exists', ->
      $q.each.should.be.ok

    it 'takes value, index and length', ->
      a = [promised(1),promised(2),promised(3)]
      b = []
      $q.each(a,(value, index, length) ->
        b.push(value, index, length)
        return
      ).then (ret) ->
        b.should.be.deep.equal([1, 0, 3, 2, 1, 3, 3, 2, 3])

      digestor.digest()

    #direct port from bluebird.each specs
    it "waits for returned promise before proceeding next", (done) ->
      a = [promised(1), promised(2), promised(3)]
      b = []
      $q.each a, (value) ->
        b.push(value)

        promised()
        .then ->
          b.push(value*2)
      .then (ret) ->
        b.should.deep.equal [1,2,2,4,3,6]
        done()

      digestor.digest()

    it "waits for returned promise before proceeding next (MIXED)", (done) ->
      a = [promised(1), 2, promised(3)]
      b = []
      $q.each a, (value) ->
        b.push(value)

        promised()
        .then ->
          b.push(value*2)
      .then (ret) ->
        b.should.deep.equal [1,2,2,4,3,6]
        done()

      digestor.digest()

    it "waits for returned thenable before proceeding next",  (done) ->
      b = [1, 2, 3]
      a = [thenabled(1), thenabled(2), thenabled(3)]
      $q.each a, (val) ->
        b.push(val * 50)
        thenabled(val * 500, b)
      .then (ret) ->
        b.should.deep.equal([1, 2, 3, 50, 500, 100, 1000, 150, 1500])
        done()
      digestor.digest()

    it "doesnt iterate with an empty array", (done) ->
      $q.each [], (val) ->
        throw new Error()
      .then (ret) ->
        ret.should.deep.equal([])
        done()
      digestor.digest()

    it "iterates with an array of single item", (done) ->
      b = []
      $q.each [promised(1)], (val) ->
        b.push(val)
        return thenabled(val*2, b)
      .then (ret) ->
        b.should.deep.equal([1,2])
        done()
      digestor.digest()

  describe 'map', ->
    mapper = (val) ->
      val * 2

    it 'exists', ->
      $q.map.should.be.ok

    it "doesnt iterate with an empty array", (done) ->
      $q.map [], (val) ->
        throw new Error()
      .then (ret) ->
        ret.should.deep.equal([])
        done()
      digestor.digest()

    #direct port from bluebird.each specs
    it "basic mapping", (done) ->
      a = [1, 2, 3]
      $q.map(a ,mapper)
      .then (mapped) ->
        mapped.should.deep.equal [2,4,6]
        done()
      digestor.digest()

    it "promise mapping", (done) ->
      a = [promised(1), promised(2), promised(3)]
      $q.map(a ,mapper)
      .then (mapped) ->
        mapped.should.deep.equal [2,4,6]
        done()
      digestor.digest()
