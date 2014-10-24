gulp = require 'gulp'

gulp.task 'build', ['otherAssets', 'webpack'], ->
  gulp.start

gulp.task 'scripts', ['build']
