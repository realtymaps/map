gulp = require 'gulp'
require './angular'
require './karma'
require './mocha'
require './watch'

gulp.task 'spec',
  gulp.series 'commonSpec', 'backendSpec', 'gulpSpec', gulp.parallel('angular', 'angularAdmin'), 'frontendSpec'

#front end coverage
gulp.task 'coverage', gulp.series "spec", ->
  gulp.src('')
  .pipe plumber()
  .pipe open '',
    url: "http://localhost:3000/coverage/chrome/index.html"
    app: "Google Chrome" #osx , linux: google-chrome, windows: chrome
