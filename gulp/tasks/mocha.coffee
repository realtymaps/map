gulp = require 'gulp'
mocha = require 'gulp-mocha'
plumber = require 'gulp-plumber'
# istanbul = require 'gulp-istanbul'
istanbul = require 'gulp-coffee-istanbul'

coffee = require 'gulp-coffee'

paths = require '../../common/config/paths'

require 'chai'
require 'should'

runMocha = (files, reporter = 'spec') ->
  gulp.src files, read: false
  .pipe plumber()
  .pipe(mocha(reporter: reporter))
  .once 'error', (err) ->
    console.log(err.stack ? err)
    process.exit(1)

gulp.task 'backendSpec', ->
  runMocha ['spec/backend/**/*spec*']

gulp.task 'commonSpec', ->
  runMocha 'spec/common/**/*spec*'

gulp.task 'gulpSpec', ->
  runMocha  'spec/gulp/**/*spec*'

gulp.task 'mocha', gulp.series 'backendSpec'

gulp.task 'coverFiles', ->
  gulp.src [paths.common, paths.backend].map (f) -> f + '*.coffee'
  .pipe istanbul()
  .pipe istanbul.hookRequire()

gulp.task 'backendCoverage', gulp.series 'coverFiles', ->
  runMocha ['spec/backend/**/*spec*', 'spec/common/**/*spec*']
  .pipe istanbul.writeReports
    dir: './_public/coverage/application/backend'
    reporters: [ 'html', 'cobertura', 'json', 'text', 'text-summary' ]
  # .pipe(istanbul.enforceThresholds(thresholds: global: 50)) #only working on gulp-istanbul
