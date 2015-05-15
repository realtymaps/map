describe 'Sanity'.ns().ns('Backend'), ->
  describe 'lodash', ->

    it 'should exist', ->
      _.should.be.ok

  describe 'should.js', ->
    it 'should exist', ->
      {}.should.be.ok
