subject = require '../../gulp/tasks/markup'
_testCb = null

describe 'gulp markup', ->
  beforeEach ->
    _testCb = null
    subject.setTestCb null

  afterEach ->
    _testCb = null
    subject.setTestCb null

  describe 'watch', ->

    ['map', 'admin'].map (name) ->
      testName:name
      camelCaseName: if name is 'map' then '' else name.toInitCaps()
    . forEach (names) ->

      describe names.testName, ->
        it 'SHOULD ONLY WATCH', (done) ->
          called = false

          _testCb = ->
            called = true

          subject.setTestCb(_testCb)
          watcher = subject["watch#{names.camelCaseName}Impl"]()

          setTimeout ->
            called.should.equal(false)
            watcher.end()
            done()
          , 200
