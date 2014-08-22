_ = require 'lodash'

describe 'Sanity'.ourNs().ourNs('Backend'), ->
  describe 'lodash', ->

    it 'should exist', ->
      _.should.be.ok

  describe 'should.js', ->
    it 'should exist', ->
      {}.should.be.ok