gulp = require 'gulp'
istanbul = require 'gulp-coffee-istanbul'
paths = require '../../common/config/paths'
logger = require('../util/logger').spawn('mocha')
require './unitPrep'
{spawn} = require('child_process')


runMocha = ({files, reporter = 'dot'}) ->
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

gulp.task 'backendUnitSpec', ->
  runMocha files:['spec/backendUnit/**/*spec*']

gulp.task 'backendUnitDebugSpec', () ->
  runMocha {files:['spec/backendUnit/**/*spec*'], reporter:'spec'}

gulp.task 'backendIntegrationSpec', () ->
  runMocha files: 'spec/backendIntegration/**/*spec*'

gulp.task 'backendIntegrationDebugSpec', () ->
  runMocha {files:'spec/backendIntegration/**/*spec*', reporter:'spec'}

gulp.task 'backendSpec', gulp.series('unitTestPrep', 'backendUnitSpec', 'unitTestTeardown', 'backendIntegrationSpec')
gulp.task 'backendDebugSpec', gulp.series('unitTestPrep', 'backendUnitDebugSpec', 'unitTestTeardown', 'backendIntegrationDebugSpec')

gulp.task 'commonSpec', () ->
  runMocha files:'spec/common/**/*spec*'

gulp.task 'gulpSpec', () ->
  runMocha files: 'spec/gulp/**/*spec*'

gulp.task 'gulpDebugSpec', () ->
  runMocha {files: "spec/gulp/**/*spec*", reporter:'spec'}

gulp.task 'coverFiles', ->
  gulp.src [paths.common, paths.backend].map (f) -> f + '*.coffee'
  # .pipe logFile(es)
  .pipe istanbul()
  .pipe istanbul.hookRequire()

gulp.task 'backendCoverage', gulp.series 'coverFiles', () ->
  runMocha(files:['spec/backend/**/*spec*', 'spec/common/**/*spec*'])
  .pipe istanbul.writeReports
    dir: './_public/coverage/application/backend'
    reporters: [ 'html', 'cobertura', 'json', 'text', 'text-summary' ]
  # .pipe(istanbul.enforceThresholds(thresholds: global: 50)) #only working on gulp-istanbul
