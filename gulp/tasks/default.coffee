gulp = require 'gulp'
help = require('gulp-help')(gulp)
clean = require 'gulp-rimraf'

gulp.task 'clean', () ->
  gulp.src('_public', { read: false })
  .pipe(clean())

#runs on port(s) 3000 & 4000
gulp.task 'pre_develop_build', ['clean'], ->
  gulp.start 'build'

gulp.task 'clean_build', ['pre_develop_build']

gulp.task 'pre_develop_watch', ['pre_develop_build'], ->
  gulp.start 'watch'

gulp.task 'develop', ['pre_develop_watch'], ->
  gulp.start 'browserSync'
  #make this happen later and all in the gulp build feed
  setTimeout ->
    gulp.start 'spec'
  , 6000

#runs on port 4000
gulp.task 'develop_no_sync', ['clean'], ->
  gulp.start 'build','express','watch'

#TODO: minify and all that jazz
gulp.task 'prod', ['clean'], ->
  gulp.start 'build','express'

gulp.task 'default', ['develop']

gulp.task "server", ['default']
gulp.task 's', ['server']
