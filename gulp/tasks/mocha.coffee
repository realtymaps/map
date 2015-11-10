gulp = require 'gulp'
mocha = require 'gulp-mocha'
plumber = require 'gulp-plumber'
istanbul = require 'gulp-coffee-istanbul'
coffee = require 'gulp-coffee'
paths = require '../../common/config/paths'
require 'chai'
require 'should'

runMocha = (files, reporter = 'dot', done) ->
  gulp.src files, read: false
  .pipe plumber()
  .pipe mocha
    reporter: reporter
    showStack: true
  .once 'error', (err) ->
    console.log(err.stack ? err)
    done()
    return process.exit(1)

gulp.task 'backendSpec', (done) ->
  runMocha ['spec/backend/**/*spec*'], undefined, done

gulp.task 'backendDebugSpec', (done) ->
  runMocha ['spec/backend/**/*spec*'], 'spec', done

gulp.task 'commonSpec', (done) ->
  runMocha 'spec/common/**/*spec*', undefined, done

gulp.task 'gulpSpec', (done) ->
  runMocha  'spec/gulp/**/*spec*', undefined, done

gulp.task 'mocha', gulp.series 'backendSpec'

gulp.task 'coverFiles', ->
  gulp.src [paths.common, paths.backend].map (f) -> f + '*.coffee'
  .pipe istanbul()
  .pipe istanbul.hookRequire()

gulp.task 'backendCoverage', gulp.series 'coverFiles', (done) ->
  runMocha ['spec/backend/**/*spec*', 'spec/common/**/*spec*'], undefined, done
  .pipe istanbul.writeReports
    dir: './_public/coverage/application/backend'
    reporters: [ 'html', 'cobertura', 'json', 'text', 'text-summary' ]
  # .pipe(istanbul.enforceThresholds(thresholds: global: 50)) #only working on gulp-istanbul
