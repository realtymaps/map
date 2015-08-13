_ = require 'lodash'
gulp = require 'gulp'
paths = require '../../common/config/paths'
plumber = require 'gulp-plumber'

getPaths = (app) ->
  return [
    paths[app].scripts
    paths[app].styles
    paths[app].rootStylus
    paths[app].stylus
    paths[app].assets
    paths[app].jade
    paths[app].html
  ]

rmapPaths = getPaths('rmap').concat([paths.common])
adminPaths = getPaths('admin').concat([paths.common])

# console.log rmapPaths, true
# console.log adminPaths, true

gulp.task 'watch_vendor', (done) ->
  gulp.watch paths.bower, gulp.series 'vendor'
  done()

gulp.task 'watch_front', (done) ->
  gulp.watch rmapPaths, gulp.series 'angular'
  done()

gulp.task 'watch_admin', (done) ->
  gulp.watch adminPaths, gulp.series 'angularAdmin'
  done()

gulp.task 'watch_all_front', gulp.series 'watch_front', 'watch_vendor', 'watch_admin'

gulp.task 'build_watch_front', gulp.series "angular", "angularAdmin", "watch_all_front"

gulp.task 'bwatch_front', gulp.series 'build_watch_front'

specCommon = "spec/common/**/*.coffee"
gulp.task 'watch', gulp.series 'watch_all_front', ->
  gulp.watch ['gulp/**/*.coffee',"spec/gulp/**/*.coffee", specCommon], gulp.series 'gulpSpec'
  gulp.watch ['backend/**/*.coffee', 'spec/backend/**/*.coffee', specCommon], gulp.series 'backendSpec'
  gulp.watch ['frontend/**/*.coffee', 'spec/app/**/*.coffee', 'spec/admin/**/*.coffee', specCommon], gulp.series 'frontendSpec'
