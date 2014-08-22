gulp = require 'gulp'
mocha = require 'gulp-mocha'

require 'chai'
require 'should'

runMocha = (files, reporter = 'spec') ->
  gulp.src files, read: false
  .pipe(mocha(reporter: reporter))

gulp.task 'backendSpec', ->
  runMocha ['spec/common/**/*spec*', 'spec/backend/**/*spec*']

gulp.task 'gulpSpec', ->
  runMocha  'spec/gulp/**/*spec*'

gulp.task 'mocha', ['backendSpec']
