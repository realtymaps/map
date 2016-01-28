gulp = require 'gulp'
{log} = require 'gulp-util'
_ = require 'lodash'
karmaKick = require 'karma-kickoff'
argv = require('yargs').argv

opts =
  configFile: '../../karma.conf.coffee'
  logFn: log

gulp.task 'karma', (done) ->
  karmaKick done, _.extend {}, opts,
    reporters:['dots', 'coverage']
    singleRun: true

gulp.task 'karmaMocha', (done) ->
  karmaKick(done, opts)

gulp.task 'karmaFiles', (done) ->
  karmaKick done, _.extend {}, opts,
    appendFiles: argv.files.split(',')
    lengthToPop: 2
    singleRun: true

###
  EASY TO DEBUG IN BROWSER
###
gulp.task 'karmaChrome', (done) ->
  karmaKick done, _.extend {}, opts,
    singleRun: false
    autoWatch: true
    reporters: ['mocha']
    browsers: ['Chrome']
    browserify:
      debug: true
      transform: ['coffeeify', 'jadeify', 'stylusify', 'brfs']

gulp.task 'frontendSpec', gulp.series 'karma'

gulp.task 'karmaNoCoverage', (done) ->
  karmaKick (code) ->
    done(code)
    process.exit code #hack this should not need to be here
  ,
    _.extend {}, opts,
      reporters: ['dots', 'junit']
      junitReporter:
        outputDir: process.env.CIRCLE_TEST_REPORTS ? 'junit'
        suite: 'realtymaps'
        useBrowserName: true

gulp.task 'frontendNoCoverageSpec', gulp.series 'karmaNoCoverage'
