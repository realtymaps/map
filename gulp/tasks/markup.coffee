require '../../common/extensions/strings'
paths = require '../../common/config/paths'
gulp = require 'gulp'
<<<<<<< HEAD
watch = require 'gulp-watch'
=======
>>>>>>> master
gutil = require 'gulp-util'
conf = require './conf'
$ = require('gulp-load-plugins')()
_ = require 'lodash'

_testCb = null

markup = (app) ->
  markupFn = () ->
    _testCb() if _testCb

    gutil.log "Building markup:", gutil.colors.bgYellow(paths[app].jade)

    gulp.src paths[app].jade.concat './node_modules/angular-busy/angular-busy.html'

    .pipe $.if('*.jade', $.consolidate('jade',
      doctype: 'html'
      pretty: '  '))
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
      templateHeader: """
      require('angular/angular');
      angular.module("<%= module %>"<%= standalone %>).run(["$templateCache", function($templateCache) {
      """
    .on   'error', conf.errorHandler 'Angular template cache'

    .pipe gulp.dest paths.temp
    .pipe $.size
      title: paths.temp
      showFiles: true

  markupFn.displayName = 'markup'
  markupFn

markupWatch = (app) ->
  # Keeps many files changing at once triggering the task over and over
  markupFn = _.debounce markup(app), 1000
  # Just for nicer gulp out
  markupFn.displayName = 'markup'

  watchPaths = paths[app].jade

  gutil.log "Watching markup files:", gutil.colors.bgYellow(watchPaths)

  watcher = watch watchPaths, conf.chokidarOpts, markupFn

  # Useful for debugging file watch issues
  # require('../util/bundleLogger').logEvents(watcher)

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
