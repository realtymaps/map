gulp = require 'gulp'
mocha = require 'gulp-mocha'
plumber = require 'gulp-plumber'

require 'chai'
require 'should'

runMocha = (files, reporter = 'spec') ->
  gulp.src files, read: false
  .pipe plumber()
  .pipe(mocha(reporter: reporter))
  .once 'error', () ->
    process.exit(1)

gulp.task 'backendSpec', ->
  runMocha ['spec/backend/**/*spec*']

gulp.task 'commonSpec', ->
  runMocha 'spec/common/**/*spec*'

gulp.task 'gulpSpec', ->
  runMocha  'spec/gulp/**/*spec*'

gulp.task 'mocha', gulp.series 'backendSpec'
