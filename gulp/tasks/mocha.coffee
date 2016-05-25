gulp = require 'gulp'
mocha = require 'gulp-mocha'
plumber = require 'gulp-plumber'
istanbul = require 'gulp-coffee-istanbul'
paths = require '../../common/config/paths'
logFile = require '../util/logFile'
es = require 'event-stream'
logger = require '../util/logger'
require './unitPrep'
dbs = require '../../backend/config/dbs'

require 'chai'
require('chai').should()
shutdown = require '../../backend/config/shutdown'


runMocha = (files, reporter = 'dot', done) ->
  gulp.src files, read: false
  # .pipe logFile(es)
  .pipe plumber()
  .pipe mocha
    reporter: reporter
    showStack: true
    timeout: 10000
  .once 'error', (err) ->
    logger.error(err.stack ? err)
    done()
    return shutdown.exit(error: true)

gulp.task 'backendUnitSpec', (done) ->
  runMocha ['spec/backendUnit/**/*spec*'], undefined, done

gulp.task 'backendUnitDebugSpec', (done) ->
  runMocha ['spec/backendUnit/**/*spec*'], 'spec', done

gulp.task 'backendIntegrationSpec', (done) ->
  runMocha ['spec/backendIntegration/**/*spec*'], undefined, done

gulp.task 'dbShutdown', (done) ->
  dbs.shutdown(quiet: true)
  .then () ->
    done()

gulp.task 'forceExit', (done) ->
  done()
  shutdown.exit()

gulp.task 'backendIntegrationDebugSpec', (done) ->
  runMocha ['spec/backendIntegration/**/*spec*'], 'spec', done

gulp.task 'backendSpec', gulp.series('unitTestPrep', 'backendUnitSpec', 'unitTestTeardown', 'backendIntegrationSpec')
gulp.task 'backendDebugSpec', gulp.series('unitTestPrep', 'backendUnitDebugSpec', 'unitTestTeardown', 'backendIntegrationDebugSpec')

gulp.task 'commonSpec', (done) ->
  runMocha 'spec/common/**/*spec*', undefined, done

gulp.task 'gulpSpec', (done) ->
  runMocha  'spec/gulp/**/*spec*', undefined, done

gulp.task 'gulpDebugSpec', (done) ->
  runMocha "spec/gulp/**/*spec*", 'spec', done

gulp.task 'coverFiles', ->
  gulp.src [paths.common, paths.backend].map (f) -> f + '*.coffee'
  # .pipe logFile(es)
  .pipe istanbul()
  .pipe istanbul.hookRequire()

gulp.task 'backendCoverage', gulp.series 'coverFiles', (done) ->
  runMocha ['spec/backend/**/*spec*', 'spec/common/**/*spec*'], undefined, done
  .pipe istanbul.writeReports
    dir: './_public/coverage/application/backend'
    reporters: [ 'html', 'cobertura', 'json', 'text', 'text-summary' ]
  # .pipe(istanbul.enforceThresholds(thresholds: global: 50)) #only working on gulp-istanbul
