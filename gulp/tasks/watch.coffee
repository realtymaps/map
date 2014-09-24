gulp = require 'gulp'
path = require '../paths'

gulp.task 'watch_rest', ->
  gulp.watch [
    path.scripts, path.styles
    path.assets,path.common
  ], ['build']
  gulp.watch ['app/**.*.coffee'], ['build']
  gulp.watch path.html, ['html']
  gulp.watch path.bower, ['vendor']

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', ['watch_rest'], ->
  # setTimeout ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], ['gulpSpec']
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon],
    ['backendSpec']
  gulp.watch ['app/**/*.coffee', 'spec/app/**/*.coffee', specCommon], ['frontendSpec']
  # , 8000
