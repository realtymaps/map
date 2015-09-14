gulp = require 'gulp'
require './angular'
require './otherAssets'
require './karma'
require './mocha'

gulp.task 'spec', gulp.series gulp.parallel('commonSpec', 'backendSpec', 'frontendSpec'), 'gulpSpec'

gulp.task 'rebuildSpec', gulp.series(
  gulp.parallel('commonSpec', 'backendSpec'), 'gulpSpec'
  , gulp.parallel('otherAssets', 'angular', 'angularAdmin'), 'frontendSpec')

gulp.task 'rspec', gulp.series 'rebuildSpec'

#front end coverage
gulp.task 'coverage', gulp.series 'spec', ->
  gulp.src('')
  .pipe plumber()
  .pipe open '',
    url: 'http://localhost:3000/coverage/chrome/index.html'
    app: 'Google Chrome' #osx , linux: google-chrome, windows: chrome
