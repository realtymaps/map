gulp = require 'gulp'
Karma = require('karma').Server
open  = require 'gulp-open'
{log} = require 'gulp-util'
_ = require 'lodash'

karmaConf = require.resolve('../../karma.conf.coffee')

karmaRunner = (done, options = {singleRun: true}, conf = karmaConf) ->
  log '-- Karma Setup --'
  _.extend options,
    configFile: conf
  try
    server = new Karma options, (code) ->
      log "Karma Callback Code: #{code}"
      done(code)
    server.start()
  catch e
    log "KARMA ERROR: #{e}"
    done(e)

console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
console.log("~~~~~~~~~~~~~~~~~~~~~~~~ #{process.env.CIRCLE_TEST_REPORTS}")
console.log("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@")
    
gulp.task 'karma', (done) ->
  karmaRunner done,
    reporters:['dots', 'coverage', 'junit']
    singleRun: true
    junitReporter:
      outputDir: process.env.CIRCLE_TEST_REPORTS ? 'junit'
      suite: 'realtymaps'

gulp.task 'karmaMocha', (done) ->
  karmaRunner(done)
###
  EASY TO DEBUG IN BROWSER
###
gulp.task 'karmaChrome', (done) ->
  karmaRunner done,
    singleRun: false
    autoWatch: true
    reporters: ['mocha']
    browsers: ['Chrome']
    browserify:
      debug: true
      transform: ['coffeeify', 'jadeify', 'stylusify', 'brfs']

gulp.task 'frontendSpec', gulp.series 'karma'

gulp.task 'karmaNoCoverage', (done) ->
  karmaRunner (code) ->
    done(code)
    process.exit code #hack this should not need to be here
  , reporters: ['dots']

gulp.task 'frontendNoCoverageSpec', gulp.series 'karmaNoCoverage'
