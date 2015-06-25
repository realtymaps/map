gulp = require 'gulp'
require './webpack'
require './karma'
require './mocha'
require './watch'

#karma, then mocha (backendSpec, gulpSpec)
#dependency order is ok because fronendSpec needs build as well so build should happen first
gulp.task 'specs', gulp.parallel 'commonSpec', 'backendSpec','gulpSpec', 'frontendSpec'

gulp.task 'spec', gulp.series 'webpack', 'webpackAdmin', 'specs'

#front end coverage
gulp.task 'coverage', gulp.series "spec", ->
  gulp.src('')
  .pipe plumber()
  .pipe open '',
    url: "http://localhost:3000/coverage/chrome/index.html"
    app: "Google Chrome" #osx , linux: google-chrome, windows: chrome
