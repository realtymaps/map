gulp = require 'gulp'

#webpack needs to be prior to html so it gets injected b4 gulp-inject
gulp.task 'build', ['vendor','images', 'webpack'], ->
  gulp.start 'html'

gulp.task 'scripts', ['build']
