require '../../common/extensions/strings'
paths = require '../../common/config/paths'
path = require 'path'
gulp = require 'gulp'
gutil = require 'gulp-util'
globby = require 'globby'
$ = require('gulp-load-plugins')()
browserify = require 'browserify'
browserify_coffeelint = require 'browserify-coffeelint'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
vinylPaths = require 'vinyl-paths'
del = require 'del'
prettyHrtime = require 'pretty-hrtime'
through = require 'through2'
conf = require './conf'
require './markup'
ignore = require 'ignore'
_ = require 'lodash'

browserifyTask = (app, watch = false) ->
  #straight from gulp , https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-with-globs.md
  # gulp expects tasks to return a stream, so we create one here.
  inputGlob = [paths.frontendCommon.root + 'scripts/**/*.coffee', paths[app].root + 'scripts/**/*.coffee']
  outputName = app + '.bundle.js'
  startTime = ''

  pipeline = (stream) ->
    stream
    .on 'error', (err) ->
      conf.errorHandler 'Bundler'
    .on 'end', ->
      timestamp = prettyHrtime process.hrtime startTime
      gutil.log 'Bundled', gutil.colors.blue(outputName), 'in', gutil.colors.magenta(timestamp)
    .pipe source outputName
    .pipe buffer()
    .pipe $.sourcemaps.init loadMaps: true
    .pipe $.sourcemaps.write()
    .pipe gulp.dest paths.destFull.scripts
    stream

  bundledStream = pipeline through()

  globby(inputGlob)
  .catch (err) ->
    # gutil.log "entries: #{entries}"
    if (err)
      bundledStream.emit('error', err)
      return
  .then (entries) ->
    config =
      entries: entries
      outputName: outputName
      dest: paths.destFull.scripts
      debug: true

    if watch
      _.extend config, watchify.args

    # This file acts like a .gitignore for excluding files from linter
    lintIgnore = ignore().addIgnoreFile __dirname + '/../../.coffeelintignore'

    b = browserify config
      .transform (file, overrideOptions = {}) ->
        if (lintIgnore.filter [file]).length == 0
          file += '.ignore'
        browserify_coffeelint file, _.extend(overrideOptions, doEmitErrors: !watch)
        .on 'error', ->
          process.exit(1)
      #  NOTE this cannot be in the config above as coffeelint will fail so the order is coffeelint first
      #  this is not needed if the transforms are in the package.json . If in JSON the transformsare ran post
      #  coffeelint.
      .transform('coffeeify')
      .transform('browserify-ngannotate', { "ext": ".coffee" })
      .transform('jadeify')
      .transform('stylusify')
      .transform('brfs')

    bundle = (stream) ->
      startTime = process.hrtime()

      globby(inputGlob)
      .then (newEntries) ->
        gutil.log 'Bundling', gutil.colors.blue(config.outputName) + ' ' + newEntries.length + ' files ...'
        b.bundle().pipe(stream)

    if watch

      watcher = gulp.watch inputGlob, conf.chokidarOpts, _.debounce () ->
        # Re-evaluate input pattern so new files are picked up
        globby(inputGlob)
        .then (newEntries) ->
          diff = _.difference newEntries, entries
          if diff.length > 0
            console.log "New files: #{diff}"
            b.add diff
            entries = newEntries
            onUpdate()
      , 1000

      # Useful for debugging file watch issues
      require('../util/bundleLogger').logEvents(watcher)

      b = watchify b

      onUpdate = _.debounce () ->
        bundle pipeline through()
      , 1000

      b.on 'update', onUpdate

      gutil.log "Watching #{entries.length} files matching", gutil.colors.yellow(inputGlob)
    else
      if config.require
        b.require config.require
      if config.external
        b.external config.external

    bundle bundledStream

  bundledStream

gulp.task 'browserify', -> browserifyTask 'map'
gulp.task 'browserifyAdmin', -> browserifyTask 'admin'

gulp.task 'browserifyAll', gulp.parallel 'browserify', 'browserifyAdmin'

###
NOTE the watches here are the odd ball of all the gulp watches we have.
They are odd in that browserify builds the script and watches at the same
time. Normally in most things we would be against this. However, due to
browserifies watchify rebuild times are greatly improved without the need
of `gulp.lastRun`.

The reason this is a problem is it requires watching to occur
at times when you don't want to (might trigger watches accidently). The main
thing here is specs can not run until all builds are finished. Therefore specs
now depends on watch.

Therefore in most conditions a watch should only watch period.
###
gulp.task 'browserifyWatch', -> browserifyTask 'map', true
gulp.task 'browserifyWatchAdmin', -> browserifyTask 'admin', true
