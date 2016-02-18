gulp = require 'gulp'
paths = require '../../common/config/paths'

specCommon = 'spec/common/**/*.coffee'

gulp.task 'watch_vendor', (done) ->
  # For some reason this watch fires multiple times
  gulp.watch paths.bower, gulp.series 'vendor'
  done()

gulp.task 'watch_all_front', gulp.parallel 'angularWatch', 'angularWatchAdmin'

gulp.task 'watch', gulp.series 'watch_all_front', (done) ->
  gulp.watch ['gulp/**/*.coffee','spec/gulp/**/*.coffee', specCommon], gulp.series 'gulpSpec'
  gulp.watch ['backend/**/*.coffee', 'spec/backendUnit/**/*.coffee', 'spec/backendIntegration/**/*.coffee', specCommon], gulp.series 'backendSpec'
  gulp.watch ['spec/frontend/**/*.coffee', specCommon], gulp.series 'karmaMocha'
  done()
