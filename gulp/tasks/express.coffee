gulp = require 'gulp'
log = require('gulp-util').log
config = require '../../backend/config/config'
argv = require('yargs').argv
{spawn} = require('child_process')
globby = require 'globby'
through = require 'through2'

globs = [
  'gulp/**/*.coffee'
  'backend/**/*.coffee'
  'common/**/*.coffee'
]

lint = (ignore) ->  () ->

  glob = globby.sync(globs)

  glob.push('-q') #show errors only

  stream = spawn('coffeelint', glob, {stdio: 'inherit'}) #note since using in inherit there is no .pipe

  if !ignore
    return stream

  retStream = through()

  stream.on('error', () ->) #sent to stdio already
  stream.on 'close', () ->
    retStream.end()
  stream.on 'end', () ->
    retStream.end()

  retStream

watch = (what) ->
  gulp.watch(globs, gulp.series(what))

run_express = ({script, ext, delay, verbose, signal} = {}) ->
  script ?= 'backend/server.coffee'
  watch ?=  ['backend', 'common']
  delay ?= 0.3
  verbose ?= true
  signal ?= 'SIGTERM'

  watch('lint')

  if argv.debug
    port = if argv.debug == true then 9999 else argv.debug
  else
    port = config.PORT

  cmd = "nodemon #{script} #{port}"
  if verbose
    cmd += " -V"

  if ext?
    cmd += " -e #{ext}"

  if delay?
    cmd += " -d #{delay}"

  if signal?
    cmd += " -s #{signal}"

  if argv.debug
    cmd += " --nodejs --debug="

  log "Running #{cmd}"

  return spawn(cmd.split(' ')[0], cmd.split(' ').slice(1), {stdio: 'inherit', env: process.env})

gulp.task 'lint', lint(true)

gulp.task 'lint:fail', lint()

gulp.task 'express', gulp.parallel 'lint', (done) ->
  run_express()
  .once 'close', (code) ->
    log('nodemon process exited with code ' + code)
    done(code)
  .once 'error', done
  done()


module.exports = {
  watch
  lint
}
