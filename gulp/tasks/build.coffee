gulp = require 'gulp'

gulp.task 'build', ['otherAssets', 'webpack'], ->
  gulp.start 'wrap'
  #gulp.start

gulp.task 'scripts', ['build']
