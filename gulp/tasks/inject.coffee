paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()
wiredep = require('wiredep').stream
_ = require 'lodash'
require './scripts'
require './styles'

gulp.task 'inject', gulp.parallel 'scripts', 'styles', ->
  injectStyles = gulp.src([
    path.join paths.tmp.styles, '/**/*.css'
    path.join '!' + paths.tmp.styles, 'vendor.css'
  ], read: false)

  injectScripts = gulp.src path.join paths.tmp.scripts, '/**/*.js'
  .pipe $.angularFilesort()
  .on 'error', (err) ->
    gutil.log gutil.colors.red('[AngularFilesort]'), err.toString()
    @emit 'end'

  injectOptions =
    ignorePath: [
      paths.rmap.root
      path.join paths.tmp.serve
    ]
    addRootSlash: false

  gulp.src 'frontend/map/index.html'
  .pipe $.inject injectStyles, injectOptions
  .pipe $.inject injectScripts, injectOptions
  .pipe wiredep conf.wiredep
  .pipe gulp.dest paths.tmp.serve
