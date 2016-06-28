gulp = require 'gulp'
require("chai").should()

describe 'Gulp Sanity', ->

  describe 'gulp', ->

    it 'should exist', ->
      gulp.should.be.ok
