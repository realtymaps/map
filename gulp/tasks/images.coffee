changed = require 'gulp-changed'
gulp = require 'gulp'
imagemin = require 'gulp-imagemin'
paths = require '../paths'
plumber = require 'gulp-plumber'

gulp.task 'images', ->
  # Ignore unchanged files
  # Optimize
  gulp.src('app/assets/**')
  .pipe plumber()
  .pipe(changed(paths.dest.root))
  .pipe(imagemin())
  .pipe gulp.dest(paths.dest.root + paths.dest.assets)


#gulp.task 'assets', () ->
#  gulp.src(path.assets)
#  .pipe(imagemin({optimizationLevel: 5}))
#  .pipe(size())
#  .pipe(gulp.dest '_public/assets')
