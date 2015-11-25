require '../../common/extensions/strings'
paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
conf = require './conf'
$ = require('gulp-load-plugins')()
_ = require 'lodash'

_testCb = null

markup = (app) ->
  markupFn = () ->
    _testCb() if _testCb

    gulp.src paths[app].jade

    .pipe $.consolidate 'jade',
      doctype: 'html'
      pretty: '  '
    .on   'error', conf.errorHandler 'Jade'

    .pipe $.minifyHtml
      empty: true
      spare: true
      quotes: true
      conditionals: true
    .on   'error', conf.errorHandler 'Minify HTML'

    .pipe $.angularTemplatecache "#{app}.templates.js",
      module: paths[app].appName
      root: '.'
    .on   'error', conf.errorHandler 'Angular template cache'

    .pipe gulp.dest paths.destFull.scripts
    .pipe $.size
      title: paths.dest.root
      showFiles: true

  markupFn.displayName = 'markup'
  markupFn

markupWatch = (app) ->
  # Options passed to gulp's underlying watch lib chokidar
  # See https://github.com/paulmillr/chokidar
  chokidarOpts =
    alwaysStat: true

  # Keeps many files changing at once triggering the task over and over
  markupFn = _.debounce markup(app), 1000
  # Just for nicer gulp out
  markupFn.displayName = 'markup'

  watcher = gulp.watch paths[app].jade, chokidarOpts, markupFn

  # Useful for debugging file watch issues
  if verbose = false
    watcher.on 'add', (path) ->
      console.log 'File', path, 'has been added'

    .on 'change', (path) ->
      console.log 'File', path, 'has been changed'

    .on 'unlink', (path) ->
      console.log 'File', path, 'has been removed'

    .on 'addDir', (path) ->
      console.log 'Directory', path, 'has been added'

    .on 'unlinkDir', (path) ->
      console.log 'Directory', path, 'has been removed'

    .on 'error', (error) ->
      console.log 'Error happened', error

    .on 'ready', ->
      console.log 'Initial scan complete. Ready for changes'

    .on 'raw', (event, path, details) ->
      console.log 'Raw event info:', event, path, details

  watcher

###
 TASKS
###
gulp.task 'markup', markup('map')

gulp.task 'markupWatch', (done) ->
  markupWatch 'map'
  done() # gulp async hint

gulp.task 'markupAdmin', markup('admin')

gulp.task 'markupWatchAdmin', (done) ->
  markupWatch 'admin'
  done() # gulp async hint

module.exports =
  ###
  For intent and purposes these exports are for testing only
  ###
  watchImpl: _.partial markupWatch, 'map'
  watchAdminImpl: _.partial markupWatch, 'admin'
  setTestCb: (cb) ->
    _testCb = cb
