gulp = require 'gulp'
minifyJS = require('gulp-uglify')
minifyCSS = require('gulp-minify-css')

gulp.task 'minify-css', ->
  gulp.src('_public/styles/*.css')
  .pipe(minifyCSS(
      advanced:true
      aggressiveMerging:true
      keepBreaks:false))
  .pipe(gulp.dest('_public/styles/'))

gulp.task 'minify-js', ->
  gulp.src('_public/scripts/vendor.js')
  .pipe(minifyJS())
  .pipe(gulp.dest('_public/scripts/'))

gulp.task 'minify', gulp.parallel 'minify-js', 'minify-css'