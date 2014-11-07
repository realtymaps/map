gulp = require 'gulp'
help = require('gulp-help')(gulp)
del = require 'del'
plumber = require 'gulp-plumber'
util = require 'gulp-util'

gulp.task 'clean', () ->
  del(['_public'])

gulp.task 'pre_develop_build', ['clean'], ->
  gulp.start ['spec','express']

gulp.task 'develop', ['pre_develop_build'], ->
  gulp.start 'watch'

gulp.task 'develop_no_sync', ['clean'], ->
  gulp.start 'build','express','watch'

#TODO: minify and all that jazz
gulp.task 'prod', ['clean'], ->
  gulp.start 'build','express'

gulp.task 'default', ['develop']

gulp.task "server", ['default']
gulp.task 's', ['server']
