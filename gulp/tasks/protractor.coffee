gulp = require('gulp')
shell = require('gulp-shell')

gulp.task('protractor', shell.task([
  'npm run protractor'
]))
