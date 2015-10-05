gulp = require 'gulp'
Karma = require('karma').Server
open  = require 'gulp-open'
{log} = require 'gulp-util'
_ = require 'lodash'

karmaConf = require.resolve('../../karma.conf.coffee')

karmaRunner = (done, options = {}) ->
  log '-- Karma Setup --'
  _.extend options,
    configFile: karmaConf
    singleRun: true
  try
    server = new Karma options, (code) ->
      log "Karma Callback Code: #{code}"
      done(code)
    server.start()
  catch e
    log "KARMA ERROR: #{e}"
    done(e)

gulp.task 'karma', (done) ->
  karmaRunner(done)

gulp.task 'frontendSpec', gulp.series 'karma'

gulp.task 'karmaNoCoverage', (done) ->
  karmaRunner (code) ->
    done(code)
    process.exit code #hack this should not need to be here
  , reporters: ['mocha']

gulp.task 'frontendNoCoverageSpec', gulp.series 'karmaNoCoverage'
