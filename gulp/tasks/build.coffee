gulp = require 'gulp'

gulp.task 'build', ['otherAssets', 'webpack']

gulp.task 'scripts', ['build']
