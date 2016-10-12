require '../../common/extensions/strings'
paths = require '../../common/config/paths'
gulp = require 'gulp'
gutil = require 'gulp-util'
globby = require 'globby'
$ = require('gulp-load-plugins')()
browserify = require 'browserify'
watchify = require 'watchify'
source = require 'vinyl-source-stream'
buffer = require 'vinyl-buffer'
prettyHrtime = require 'pretty-hrtime'
through = require 'through2'
conf = require './conf'
mainConfig = require '../../backend/config/config'
require './markup'
ignore = require 'ignore'
_ = require 'lodash'
logger = (require '../util/logger').spawn('scripts')
shutdown = require '../../backend/config/shutdown'

coffeelint = require('coffeelint')
coffeelint.reporter = require('coffeelint-stylish').reporter
coffeelint.configfinder = require('coffeelint/lib/configfinder')


browserifyTask = ({app, watch, prod, doSourceMaps}) ->
  prod ?= false
  watch ?= false
  doSourceMaps ?= if prod == true then false else true

  #straight from gulp , https://github.com/gulpjs/gulp/blob/master/docs/recipes/browserify-with-globs.md
  # gulp expects tasks to return a stream, so we create one here.
  inputGlob = ['js', 'coffee'].map (ext) ->
    [
      paths.frontendCommon.root + 'scripts/**/*.' + ext
      '-' + paths.frontendCommon.root + 'scripts/**/*prod.' + ext
      paths[app].root + 'scripts/**/*.' + ext
      '-' + paths[app].root + 'scripts/**/*prod.' + ext
    ]

  inputGlob = _.flatten inputGlob

  if prod
    inputGlob = _.filter inputGlob, (glob) ->
      !glob.match(/\-/g)

  outputName = app + '.bundle.js'
  startTime = ''

  logger.debug -> "@@@@ inputGlob @@@@"
  logger.debug -> inputGlob
  logger.debug -> "@@@@@@@@@@@@@@@@@@@"

  pipeline = (stream) ->

    s2 = stream
    .on 'error', (err) ->
      conf.errorHandler 'Bundler'
    .on 'end', ->
      timestamp = prettyHrtime process.hrtime startTime
      logger.debug 'Bundled', gutil.colors.blue(outputName), 'in', gutil.colors.magenta(timestamp)

    .pipe source outputName
    .pipe buffer()

    if doSourceMaps
      logger.debug 'doing sourcemaps'

      s2.pipe $.sourcemaps.init {loadMaps: true, largeFile: true}
      .pipe $.sourcemaps.write()

    s2.pipe gulp.dest paths.destFull.scripts
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

        errorReport = coffeelint.getErrorReport()
        fileOptions = coffeelint.configfinder.getConfig() or {}
        options = _.defaults(overrideOptions, fileOptions)

        options.doEmitErrors = !watch

        errors = null

        # Taken from browserify-coffeelint
        transform = (buf, enc, next) ->
          if file.substr(-7) == '.coffee'
            errors = errorReport.lint(file, buf.toString(), options)
            if errors.length != 0
              coffeelint.reporter file, errors
              if options.doEmitErrors and errorReport.hasError()
                next new Error(errors[0].message)
              if options.doEmitWarnings and _.any(errorReport.paths, (p) -> errorReport.pathHasWarning p)
                next new Error(errors[0].message)
          @push buf
          next()

        # If coffeelint found errors, append console.warns/errors to the end of the file
        # Additionally add a javascript alert (if this is the first file with errors), to draw attention to the console
        flush = (next) ->
          if errors?.length
            _.each errors, (error) =>
              {level, lineNumber, message, context} = error
              log = if level is 'error' then 'error' else 'warn'
              msg = "Coffeelint #{level} @ #{file}:#{lineNumber} #{message}".replace(/'/g, "\\'")
              @push "console.#{log} '#{msg}'\n"
              @push "alert window.lintAlert = 'LINT ERRORS SEE CONSOLE' if not window.lintAlert\n"

          next()

        through transform, flush
      .on 'error', (error) ->
        shutdown.exit(error: true)

      #  NOTE this cannot be in the config above as coffeelint will fail so the order is coffeelint first
      #  this is not needed if the transforms are in the package.json . If in JSON the transformsare ran post
      #  coffeelint.
      .transform('coffeeify', sourceMap: if doSourceMaps then mainConfig.COFFEE_SOURCE_MAP else false)
      .transform('browserify-ngannotate', { "ext": ".coffee" })
      .transform('jadeify')
      .transform('stylusify')
      .transform('brfs')

    bundle = (stream) ->
      startTime = process.hrtime()

      globby(inputGlob)
      .then (newEntries) ->
        logger.debug 'Bundling', gutil.colors.blue(config.outputName) + ' ' + newEntries.length + ' files ...'
        b.bundle().pipe(stream)

    if watch

      watcher = gulp.watch inputGlob, conf.chokidarOpts, _.debounce () ->
        # Re-evaluate input pattern so new files are picked up
        globby(inputGlob)
        .then (newEntries) ->
          diff = _.difference newEntries, entries
          if diff.length > 0
            logger.debug "New files: #{diff}"
            b.add diff
            entries = newEntries
            onUpdate()
      , 1000

      # Useful for debugging file watch issues
      # require('../util/bundleLogger').logEvents(watcher)

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

gulp.task 'browserify', -> browserifyTask app: 'map'
gulp.task 'browserifyAdmin', -> browserifyTask app:'admin'

gulp.task 'browserifyProd', -> browserifyTask app: 'map', prod:true
gulp.task 'browserifyAdminProd', -> browserifyTask app:'admin', prod: true

gulp.task 'browserifyAll', gulp.parallel 'browserify', 'browserifyAdmin'
gulp.task 'browserifyAllProd', gulp.parallel 'browserifyProd', 'browserifyAdminProd'

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
gulp.task 'browserifyWatch', -> browserifyTask app: 'map', watch: true
gulp.task 'browserifyWatchAdmin', -> browserifyTask app: 'admin', watch: true
