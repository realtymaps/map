gulp = require 'gulp'
require './angular'
require './otherAssets'
require './karma'
require './mocha'
open = require 'gulp-open'

gulp.task 'spec', gulp.series gulp.parallel('commonSpec', 'backendSpec', 'frontendSpec'), 'gulpSpec'

gulp.task 'rebuildSpec', gulp.series(
  gulp.parallel('commonSpec', 'backendSpec'), 'gulpSpec'
  , gulp.parallel('otherAssets', 'angular', 'angularAdmin'), 'frontendNoCoverageSpec')

gulp.task 'rspec', gulp.series 'rebuildSpec'

#front end coverage
gulp.task 'openCoverage', ->
  gulp.src('')
  .pipe open
    uri: 'http://localhost:8085/coverage/application/index.html'
    app: 'Google Chrome' #osx , linux: google-chrome, windows: chrome

gulp.task 'rcoverage', gulp.series 'vendor', 'frontendSpec', 'openCoverage'
