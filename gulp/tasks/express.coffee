gulp = require 'gulp'
shell = require('gulp-shell')
log = require('gulp-util').log
config = require '../../backend/config/config'
coffeelint = require 'gulp-coffeelint'
argv = require('yargs').argv

run_express = ({script, ext, watch, delay, verbose, signal} = {}) ->
  script ?= 'backend/server.coffee'
  watch ?=  ['backend', 'common']
  delay ?= 0.3
  verbose ?= true
  signal ?= 'SIGTERM'

  if argv.debug
    port = if argv.debug == true then 9999 else argv.debug
  else
    port = config.PORT

  watch = watch.map((n) -> "-w #{n}").join(' ')

  cmd = "nodemon #{script} #{port} #{watch}"
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

  shell.task([cmd], continue:true)


gulp.task 'lint', () ->
  gulp.src [
    'gulp/**/*.coffee'
    'backend/**/*.coffee'
    'common/**/*.coffee'
  ]
  .pipe coffeelint()
  .pipe coffeelint.reporter()

gulp.task 'express', gulp.parallel 'lint', run_express()
