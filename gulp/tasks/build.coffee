gulp = require 'gulp'

#webpack needs to be prior to html so it gets injected b4 gulp-inject
gulp.task 'build', ['vendor','images', 'webpack'], ->
  gulp.start 'wrap', 'html', 'stylus'

gulp.task 'scripts', ['build']
