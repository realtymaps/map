gulp = require 'gulp'
help = require('gulp-help')(gulp)
del = require 'del'
plumber = require 'gulp-plumber'
util = require 'gulp-util'

gulp.task 'clean', (done) ->
  # done is absolutely needed to let gulp known when this async task is done!!!!!!!
  del ['_public'], done

#gulp dependency hell
gulp.task 'develop', ['clean'], ->
  gulp.start ['spec', 'express_spec', 'watch']

gulp.task 'mock', ['clean'], ->
  gulp.start ['specMock', 'jsonMock', 'express_spec', 'watch']

gulp.task 'develop_no_spec', ['clean'], ->
  gulp.start ['build', 'express', 'watch']

gulp.task 'prod', ['clean'], ->
  gulp.start ['build', 'express']

gulp.task 'default', ['develop']

gulp.task "server", ['default']
gulp.task 's', ['server']