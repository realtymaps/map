gulp = require 'gulp'
require './angular'
require './otherAssets'
require './karma'
require './mocha'

gulp.task 'spec',
  gulp.series 'commonSpec', 'backendSpec', 'gulpSpec', 'otherAssets', 'angular', 'angularAdmin', 'frontendSpec'

#front end coverage
gulp.task 'coverage', gulp.series 'spec', ->
  gulp.src('')
  .pipe plumber()
  .pipe open '',
    url: 'http://localhost:3000/coverage/chrome/index.html'
    app: 'Google Chrome' #osx , linux: google-chrome, windows: chrome
