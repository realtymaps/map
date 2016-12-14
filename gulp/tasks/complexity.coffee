gulp = require 'gulp'
complexity = require 'gulp-complexity'

gulp.task 'complexityBackend', ->
  gulp.src ['backend/**/*.coffee', 'common/**/*.coffee']
  .pipe complexity
    breakOnErrors:false

gulp.task 'complexityFrontend', ->
  gulp.src ['frontend/**/*.coffee']
  .pipe complexity
    breakOnErrors:false

gulp.task 'complexity', gulp.series 'complexityBackend', 'complexityFrontend'
