gulp = require 'gulp'

describe 'Gulp Sanity'.ns().ns('gulp'), ->

  describe 'gulp', ->

    it 'should exist', ->
      gulp.should.be.ok
