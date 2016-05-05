gulp = require 'gulp'
{log} = require 'gulp-util'
_ = require 'lodash'
karmaKick = require 'karma-kickoff'
argv = require('yargs').argv
shutdown = require '../../backend/config/shutdown'


opts =
  configFile: '../../karma.conf.coffee'
  logFn: log

gulp.task 'karmaCoverage', (done) ->
  karmaKick done, _.extend {}, opts,
    reporters:['dots', 'coverage']
    singleRun: true
    browserify:
      transform: ['coffeeify', 'jadeify', 'stylusify', 'brfs',
        ["browserify-istanbul",
          ignore: ["spec/**/*"]
          #https://github.com/karma-runner/karma-coverage/issues/157#issuecomment-160555004
          #fixes the text karma-coverage error
          instrumenterConfig: { embedSource: true }
        ]
      ]

gulp.task 'karmaMocha', (done) ->
  karmaKick done, opts

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

gulp.task 'karma', (done) ->
  karmaKick (code) ->
    done(code)
    if code
      shutdown.exit(error: true)  #hack this should not need to be here
  ,
    _.extend {}, opts,
      reporters: ['dots', 'junit']
      junitReporter:
        outputDir: process.env.CIRCLE_TEST_REPORTS ? 'junit'
        suite: 'realtymaps'
        useBrowserName: true

gulp.task 'frontendCoverageSpec', gulp.series 'karmaCoverage'

gulp.task 'frontendSpec', gulp.series 'karma'
