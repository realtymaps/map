gulp = require 'gulp'
help = require('gulp-help')(gulp)
del = require 'del'
plumber = require 'gulp-plumber'
util = require 'gulp-util'

gulp.task 'clean', (done) ->
  # done is absolutley needed to let gulp known when this async task is done!!!!!!!
  del ['_public'], done

#gulp dependency hell
gulp.task 'develop', ['clean', 'spec', 'express','watch']

gulp.task 'develop_no_spec', ['clean', 'build','express','watch']

gulp.task 'prod', ['clean', 'build','express']

gulp.task 'default', ['develop']

gulp.task "server", ['default']
gulp.task 's', ['server']