gulp = require 'gulp'
path = require '../paths'
wrap = require 'gulp-wrap'
plumber = require 'gulp-plumber'

gulp.task 'wrap', ->
  #async wrapper around main package
  gulp.src(path.destFull.scripts + '/main.wp.js', base:'./')
  .pipe plumber()
  .pipe(wrap 'Promise.promisify(function(){<%= contents %>\n})();')
  .pipe(gulp.dest './')#overwrite
