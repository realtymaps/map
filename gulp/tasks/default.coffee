gulp = require 'gulp'
help = require('gulp-help')(gulp)
clean = require 'gulp-rimraf'


#runs on port(s) 3000 & 4000
gulp.task 'pre_develop_build', ['clean'], ->
  gulp.start 'build'

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

gulp.task 'default', ['develop']

gulp.task 'clean', () ->
  gulp.src('_public', { read: false })
  .pipe(clean())

gulp.task "server", ['default']
gulp.task 's', ['server']
