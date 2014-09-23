gulp = require 'gulp'
path = require '../paths'

gulp.task 'watch_rest', ->
  gulp.watch [path.scripts,path.styles,path.bower,
  path.assets,path.common], ['build']
  gulp.watch ['app/**'], ['build']
  gulp.watch path.html, ['html']
  gulp.watch path.bower, ['vendor']

specCommon = "spec/common/**"
gulp.task 'watch', ['watch_rest'], ->
  setTimeout ->
    #gulp.watch path.spec, ['spec']
    gulp.watch ['gulp/**',"spec/gulp/**", specCommon], ['gulpSpec']
    gulp.watch ['backend/**', 'spec/backend/**', specCommon], ['backendSpec']
    gulp.watch ['app/**', 'spec/app/**', specCommon], ['frontendSpec']
  , 8000
