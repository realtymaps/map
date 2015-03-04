gulp = require 'gulp'
require './webpack'

gulp.task 'build', gulp.parallel 'webpack'
