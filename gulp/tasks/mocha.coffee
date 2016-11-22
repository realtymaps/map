gulp = require 'gulp'
istanbul = require 'gulp-coffee-istanbul'
paths = require '../../common/config/paths'
logger = require('../util/logger').spawn('mocha')
require './unitPrep'
{spawn} = require('child_process')


runMocha = ({files, reporter = 'dot'}, done) ->
  spawn('mocha', [
    "--reporter"
    reporter
    "--timeout"
    "10000"
    "--compilers"
    "coffee:coffee-script/register"
    "--full-trace"
    if Array.isArray(files) then files.join(' ') else files
  ], stdio: 'inherit')
  .once 'close', done
  .once 'finish', done
  .once 'error', done

gulp.task 'backendUnitSpec', (done) ->
  runMocha files:['spec/backendUnit/**/*spec*'], done

gulp.task 'backendUnitDebugSpec', (done) ->
  runMocha {files:['spec/backendUnit/**/*spec*'], reporter:'spec'}, done

gulp.task 'backendIntegrationSpec', (done) ->
  runMocha files: 'spec/backendIntegration/**/*spec*', done

gulp.task 'backendIntegrationDebugSpec', (done) ->
  runMocha {files:'spec/backendIntegration/**/*spec*', reporter:'spec'}, done

gulp.task 'backendSpec', gulp.series('unitTestPrep', 'backendUnitSpec', 'unitTestTeardown', 'backendIntegrationSpec')
gulp.task 'backendDebugSpec', gulp.series('unitTestPrep', 'backendUnitDebugSpec', 'unitTestTeardown', 'backendIntegrationDebugSpec')

gulp.task 'commonSpec', (done) ->
  runMocha files:'spec/common/**/*spec*', done

gulp.task 'gulpSpec', (done) ->
  runMocha  files: 'spec/gulp/**/*spec*', done

gulp.task 'gulpDebugSpec', (done) ->
  runMocha {files: "spec/gulp/**/*spec*", reporter:'spec'}, done

gulp.task 'coverFiles', ->
  gulp.src [paths.common, paths.backend].map (f) -> f + '*.coffee'
  # .pipe logFile(es)
  .pipe istanbul()
  .pipe istanbul.hookRequire()

gulp.task 'backendCoverage', gulp.series 'coverFiles', (done) ->
  runMocha files:['spec/backend/**/*spec*', 'spec/common/**/*spec*'], done
  .pipe istanbul.writeReports
    dir: './_public/coverage/application/backend'
    reporters: [ 'html', 'cobertura', 'json', 'text', 'text-summary' ]
  # .pipe(istanbul.enforceThresholds(thresholds: global: 50)) #only working on gulp-istanbul
